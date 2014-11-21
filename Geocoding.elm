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

data Response
    = OK [Maybe Geocode] 
    | ZeroResults
    | OverQueryLimit
    | RequestDenied
    | InvalidRequest
    | UnknownError
    | MalformedResponse     -- Not in Google original spec, added for completion

byAddress : Signal GeocodeRequest -> Signal (Http.Response Geocode)
byAddress = Native.Geocoding.byAddress

-- Response transformer
--transformResponse : Http.Response String -> Http.Response Response
--transformResponse resp = 
--    case resp of
--        Http.Success str -> Http.Success (parseResponse str)
--        Http.Waiting -> Http.Waiting
--        Http.Failure code err -> Http.Failure code err

--parseResponse : String -> Response
--parseResponse str =
--    case (Json.fromString str) of
--        Just (Json.Object dict) ->
--            case (Dict.get "status" dict) of 
--                Just (Json.String "OK") ->
--                    case (Dict.get "results" dict) of 
--                        Just (Json.Array values) -> OK (map parseGeocode (values))
--                        _ -> MalformedResponse
--                Just (Json.String "ZERO_RESULTS") -> ZeroResults
--                Just (Json.String "OVER_QUERY_LIMIT") -> OverQueryLimit
--                Just (Json.String "REQUEST_DENIED") -> RequestDenied
--                Just (Json.String "INVALID_REQUEST") -> InvalidRequest
--                Just (Json.String "UNKNOWN_ERROR") -> UnknownError
--                _ -> MalformedResponse
--        _ -> MalformedResponse

--parseGeocode : Json.Value -> Maybe Geocode
--parseGeocode jval =
--    case jval of 
--        Json.Object dict ->
--            (Dict.get "geometry" dict) >>= (\geometry ->
--            (parseGeometry geometry) >>= (\geometry ->
--                return {geometry=geometry}
--            ))
--        _ -> Nothing

--parseGeometry : Json.Value -> Maybe Geometry
--parseGeometry jval =
--    case jval of
--        Json.Object dict ->
--            (Dict.get "location" dict) >>= (\location ->
--            (Dict.get "viewport" dict) >>= (\viewport ->
--            (parseLocation location) >>= (\location ->
--            (parseBounds viewport) >>= (\viewport ->
--                return {location=location, viewport=viewport}
--            ))))
--        _ -> Nothing

--parseBounds : Json.Value -> Maybe Bounds
--parseBounds jval =
--    case jval of 
--        Json.Object dict ->
--            (Dict.get "northeast" dict) >>= (\ne ->
--            (Dict.get "southwest" dict) >>= (\sw ->
--            (parseLocation ne) >>= (\ne ->
--            (parseLocation sw) >>= (\sw ->
--                return {northeast=ne, southwest=sw}
--            ))))
--        _ -> Nothing

--parseLocation : Json.Value -> Maybe Location
--parseLocation jval =
--    case jval of 
--        Json.Object dict ->
--            (getJsonNumber <| Dict.get "lat" dict) >>= (\lat ->
--            (getJsonNumber <| Dict.get "lng" dict) >>= (\lng ->
--                return {lat=lat, lng=lng}
--            ))
--        _ -> Nothing

---- Embed our own monad and JSON helpers

--getJsonNumber : Maybe Json.Value -> Maybe Float
--getJsonNumber jval = 
--    case jval of 
--        Just (Json.Number x) -> Just x
--        _ -> Nothing

--(>>=) : Maybe a -> (a -> Maybe b) -> Maybe b
--(>>=) x f =
--    case x of 
--        Just y -> f y
--        Nothing -> Nothing

--return : a -> Maybe a
--return x = Just x

