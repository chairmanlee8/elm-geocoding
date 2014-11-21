Elm.Native.Geocoding = {};
Elm.Native.Geocoding.make = function(elm) {
    elm.Native = elm.Native || {};
    elm.Native.Geocoding = elm.Native.Geocoding || {};
    if (elm.Native.Geocoding.values) return elm.Native.Geocoding.values;

    var List = Elm.List.make(elm);
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

    function sendReq(queue,responses,req) {
        var response = { value: { ctor:'Waiting' } };
        queue.push(response);

        var geocoder = new google.maps.Geocoder();
        geocoder.geocode({'address': req.address}, function (results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                response.value = { ctor: 'Success', _0: {
                    geometry: {
                        location: {
                            lat: results[0].geometry.location.lat(),
                            lng: results[0].geometry.location.lng()
                        },
                        viewport: {
                            northeast: {
                                lat: results[0].geometry.viewport.getNorthEast().lat(),
                                lng: results[0].geometry.viewport.getNorthEast().lng()
                            },
                            southwest: {
                                lat: results[0].geometry.viewport.getSouthWest().lat(),
                                lng: results[0].geometry.viewport.getSouthWest().lng()
                            }
                        }
                    }
                }};
            } else {
                response.value = { ctor: 'Failure', _0: 500, _1: "Geocoder failed." };
            }

            setTimeout(function() { updateQueue(queue, responses); }, 0);
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
