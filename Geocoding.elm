module Geocoding where
{-| Elm interface to the Google Maps Geocoding v3 API. Also includes interface to Static Maps API for map display. Names and metanames try as best as possible to conform to the original JavaScript API.

The use of this library requires that the Google Maps JavaScript is embedded on your page with a working API key. This could be as easy as including a script tag in your document head (for elm-html users), or adding it as a compiler flag for pure Elm. Asynchronously mounting the JavaScript library is a little trickier -- inspect the example/ directory on the GitHub page for this library for details.

# API Interface
@docs byAddress, isFailure

# Static Maps
@docs mapUrl, calcZoom

# Types and Constructors
@docs Location, Bounds, Geometry, Address, Geocode, GeocodeRequest, GeocodeResponse, GeocoderStatus

# Type Displays
@docs showStatus, showLatitude, showLongitude

-}

import String
import Dict
import Http
import Native.Geocoding

-- Geocoding API v3
-- https://developers.google.com/maps/documentation/geocoding/
-- https://developers.google.com/maps/documentation/javascript/geocoding

type alias Location = {lat : Float, lng : Float}
type alias Bounds = {northeast : Location, southwest : Location}

type alias Geometry = 
    { location              : Location
    , viewport              : Bounds
    , bounds                : Maybe Bounds
    }

type alias Address =
    { short_name            : String
    , long_name             : String
    , postcode_localities   : List String
    , types                 : List String
    }

type alias Geocode = 
    { types                 : List String
    , formatted_address     : String
    , address_components    : List Address
    , geometry              : Geometry
    , partial_match         : Bool
    }

type alias GeocodeRequest =
    { address       : String
    }

type GeocodeResponse
    = Success (List Geocode)
    | Waiting 
    | Failure GeocoderStatus

type GeocoderStatus
    = OK
    | ZeroResults
    | OverQueryLimit
    | RequestDenied
    | InvalidRequest

{-| Convert a GeocoderStatus into a human-readable string.

    showStatus ZeroResults == "No results found."
-}
showStatus : GeocoderStatus -> String
showStatus status =
    case status of 
        OK ->               "OK."
        ZeroResults ->      "No results found."
        OverQueryLimit ->   "Exceeded query limit."
        RequestDenied ->    "Request denied."
        InvalidRequest ->   "Invalid request."
        _ ->                "Unknown error."

{-| Convert a location's latitude into a human-readable string.

    showLatitude {lat: 60.5, lng: -30.3} == "N 60 30 0"
-}
showLatitude : Location -> String
showLatitude location =
    let ns = if (location.lat > 0) then "N " else "S "
        d = abs location.lat
        m = (d - toFloat (floor d)) * 60
        s = (m - toFloat (floor m)) * 60
    in
        ns ++ toString (floor d) ++ "° " ++ toString (floor m) ++ "′ " ++ toString (floor s) ++ "″"

{-| Convert a location's longitude into a human-readable string.

    showLongitude {lat: 60.5, lng: -30.3} == "W 30 18 0"
-}
showLongitude : Location -> String
showLongitude location =
    let ns = if (location.lng > 0) then "E " else "W "
        d = abs location.lng
        m = (d - toFloat (floor d)) * 60
        s = (m - toFloat (floor m)) * 60
    in
        ns ++ toString (floor d) ++ "° " ++ toString (floor m) ++ "′ " ++ toString (floor s) ++ "″"

{-| Check if a GeocodeResponse was a failure or not. 
    
    isFailure Failure _ = True
    isFailure Waiting = False
    isFailure Success _ = False
-}
isFailure : GeocodeResponse -> Bool
isFailure gr = 
    case gr of
        Failure _ -> True
        _ -> False

{-| Interface to Google Maps Geocoder API. Given an address or location as a search term, returns a list of possible locations. As an asynchronous request, byAddress is structured as a Signal transformer, transforming GeocodeRequest signals to GeocodeResponses. It is recommended to debounce the input signal, otherwise you may get receive OverQueryLimit from Google (rate limit).

    byAddress {address="Chicago, IL"}
-}
byAddress : Signal GeocodeRequest -> Signal GeocodeResponse
byAddress = Native.Geocoding.byAddress

-- Display Maps
-- https://developers.google.com/maps/documentation/staticmaps/

{-| Get the URL for a static Google map, given a location, zoom, and image dimensions. The URL can then be set on an Image element for display. Zoom ranges from 1-12, with 1 being the most zoomed out.
-}
mapUrl : Location -> Int -> (Int, Int) -> String
mapUrl coords zoom (width, height) = 
    "https://maps.googleapis.com/maps/api/staticmap?" 
        ++ "center=" ++ (toString coords.lat) ++ "," ++ (toString coords.lng) ++ "&"
        ++ "zoom=" ++ (toString zoom) ++ "&"
        ++ "size=" ++ (toString width) ++ "x" ++ (toString height)

{-| Calculate the zoom factor from viewport bounds. This is helpful when deciding what zoom to pass to mapUrl, when you have a Geocode from byAddress. The canonical usage is as follows. Notice how the width is repeated twice.

    gc = Geocode ...
    mapUrl gc.geometry.location (calcZoom gc.geometry.viewport 500) (500, 300)
-}
calcZoom : Bounds -> Int -> Int
calcZoom viewport displayWidth =
    let globeWidth = 256.0  -- a constant in Google Maps' projection
        angle = viewport.northeast.lng - viewport.southwest.lng
        adjAngle = if (angle < 0) then (angle + 360) else angle
    in
        round (logBase 2 ((toFloat displayWidth) * 360 / angle / globeWidth))

