Elm.Native.Geocoding = {};
Elm.Native.Geocoding.make = function(elm) {
    elm.Native = elm.Native || {};
    elm.Native.Geocoding = elm.Native.Geocoding || {};
    if (elm.Native.Geocoding.values) return elm.Native.Geocoding.values;

    var Native$List = Elm.Native.List.make(elm);
    var Signal = Elm.Signal.make(elm);
    var Http = Elm.Http.make(elm);

    function registerReq(queue,responses) {
        return function(req) {
            sendReq(queue,responses,req);
        };
    }

    function updateQueue(queue,responses) {
        if (queue.length > 0) {
            elm.notify(responses.id, queue[0].value);
            if (queue[0].value.ctor !== 'Waiting') {
                queue.shift();
                setTimeout(function() { updateQueue(queue,responses); }, 0);
            }
        }
    }

    function makeLocation (x) { return {lat: x.lat(), lng: x.lng()}; }
    function makeBounds (x) { return {northeast: makeLocation(x.getNorthEast()), southwest: makeLocation(x.getSouthWest())}; }

    function makeGeometry (x) {
        return {
            location: makeLocation(x.location),
            viewport: makeBounds(x.viewport),
            bounds: x.bounds ? {ctor: 'Just', _0: makeBounds(x.bounds)} : {ctor: 'Nothing'}
        }
    }

    function makeAddressComponent(x) {
        return {
            short_name: x.short_name,
            long_name: x.long_name,
            postcode_localities: Native$List.fromArray(x.postcode_localities || []),
            types: Native$List.fromArray(x.types || [])
        }
    }

    function makeGeocode (x) {
        return {
            types: Native$List.fromArray(x.types || []),
            formatted_address: x.formatted_address || "",
            address_components: Native$List.fromArray((x.address_components || []).map(makeAddressComponent)),
            partial_match: x.partial_match || false,
            geometry: makeGeometry(x.geometry)
        }
    }

    function sendReq(queue,responses,req) {
        var response = { value: { ctor:'Waiting' } };
        queue.push(response);

        var geocoder = new google.maps.Geocoder();
        geocoder.geocode({'address': req.address}, function (results, status) {
            var updateResult = false;

            if (status == google.maps.GeocoderStatus.OK) {
                response.value = {
                    ctor: 'Success',
                    _0: Native$List.fromArray(results.map(makeGeocode))
                };

                updateResult = true;
            } else {
                var failcode = null,
                    s = google.maps.GeocoderStatus;

                switch (status) {
                    case s.ZERO_RESULTS:     failcode = {ctor: 'ZeroResults'};       break;
                    case s.OVER_QUERY_LIMIT: failcode = {ctor: 'OverQueryLimit'};    break;
                    case s.REQUEST_DENIED:   failcode = {ctor: 'RequestDenied'};     break;
                    case s.INVALID_REQUEST:  failcode = {ctor: 'InvalidRequest'};    break;
                }

                // Warning: unknown status (failcode==null) will result in forever waiting state.
                if (failcode != null) {
                    response.value = {ctor: 'Failure', _0: failcode};
                    updateResult = true;
                }
            }

            if (updateResult) {
                setTimeout(function() { updateQueue(queue, responses); }, 0);
            }
        });
    }

    function byAddress(requests) {
        var responses = Signal.constant(elm.Geocoding.values.Waiting);
        var sender = A2( Signal.map, registerReq([],responses), requests );
        function f(x) { return function(y) { return x; } }
        return A3( Signal.map2, f, responses, sender );
    }
      
    return elm.Native.Geocoding.values = {
        byAddress:byAddress
    };
};
