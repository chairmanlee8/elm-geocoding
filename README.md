elm-geocoding
=============

Elm interface to Google Maps' geocoding library.
Requires Google Maps API in global scope.

Build and Run Test
------------------

To build the test harness, run `elm-get install` followed by `make.sh`. Change into the `test` directory and run `python -m http.server` (Python 3) or `python -m SimpleHTTPServer` (Python 2). Navigate to `localhost:8000/test.html` in your browser of choice.

The test will require that you input a Google API key, which can be acquired from the Google Developer Center. Make sure to set your allowed referers, otherwise Google Maps API will complain.

![](API Key.png)