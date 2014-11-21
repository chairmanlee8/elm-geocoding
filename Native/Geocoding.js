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

    function makeGeocode (result) {
        return {
            geometry: {
                location: {
                    lat: result.geometry.location.lat(),
                    lng: result.geometry.location.lng()
                },
                viewport: {
                    northeast: {
                        lat: result.geometry.viewport.getNorthEast().lat(),
                        lng: result.geometry.viewport.getNorthEast().lng()
                    },
                    southwest: {
                        lat: result.geometry.viewport.getSouthWest().lat(),
                        lng: result.geometry.viewport.getSouthWest().lng()
                    }
                }
            }
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
        var responses = Signal.constant(Http.Waiting);
        var sender = A2( Signal.lift, registerReq([],responses), requests );
        function f(x) { return function(y) { return x; } }
        return A3( Signal.lift2, f, responses, sender );
    }
      
    return elm.Native.Geocoding.values = {
        byAddress:byAddress
    };
};
