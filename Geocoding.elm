module Geocoding where

import String
import Dict
import Json
import Http
import Native.Geocoding

-- Geocoding API v3
-- https://developers.google.com/maps/documentation/geocoding/

type Location = {lat : Float, lng : Float}
type Bounds = {northeast : Location, southwest : Location}

type Geometry = 
    { location  : Location
    , viewport  : Bounds
    }

type Geocode = 
    { geometry  : Geometry
    }

type GeocodeRequest =
    { address   : String
    }

data GeocodeResponse
    = Success [Geocode]
    | Waiting 
    | Failure GeocoderStatus

data GeocoderStatus
    = OK
    | ZeroResults
    | OverQueryLimit
    | RequestDenied
    | InvalidRequest

byAddress : Signal GeocodeRequest -> Signal GeocodeResponse
byAddress = Native.Geocoding.byAddress

-- Display Maps

-- Turn lat/long coords + zoom into embedded Google Map link
--mapUrl : String -> Float -> Float -> Int -> String
--mapUrl apiKey lat lng zoom = 
--    "https://www.google.com/maps/embed/v1/view?key=" ++ apiKey ++ "&center=" ++ (show lat) ++ "," ++ (show lng) ++ "&zoom=" ++ (show zoom)

--mapHtml : String -> Float -> Float -> Int -> Html
--mapHtml apiKey lat lng zoom =
--    iframe []

-- Calculate zoom from map bounds and desired pixel width
--calcZoom : [Float] -> Int -> Int
--calcZoom bounds displayWidth =
--    case bounds of 
--        _::l::_::r::[] ->
--            let globeWidth = 256.0  -- a constant in Google Maps' projection
--                angle = r - l
--                adjAngle = if (angle < 0) then (angle + 360) else angle
--            in
--                round (logBase 2 ((toFloat displayWidth) * 360 / angle / globeWidth))

--        _ -> 10

