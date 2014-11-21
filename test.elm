module Test where

import Time (..)
import Graphics.Input as Input
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Http
import Window

import Geocoding

aLocation : Input.Input String
aLocation = Input.input ""

view : Http.Response Geocoding.Geocode -> Html
view resp =
    let resultStr = 
            case resp of 
                Http.Success gc -> "Lat " ++ (show gc.geometry.location.lat) ++ ", Lng " ++ (show gc.geometry.location.lng)
                Http.Waiting -> "Waiting"
                _ -> "Error"
    in
        div
            []
            [ input [ type' "text", placeholder "Enter address or location...", on "keyup" getValue aLocation.handle identity ] []
            , div [] [ text resultStr ]
            ]

scene : (Int, Int) -> Http.Response Geocoding.Geocode -> Element
scene (w, h) gc = toElement w h (view gc)

main : Signal Element
main = scene <~ Window.dimensions
              ~ Geocoding.byAddress (lift (\addr -> {address=addr}) (debounce (5 * second) aLocation.signal))

-- Rate-limiter
debounce : Time -> Signal a -> Signal a
debounce wait signal = sampleOn (since wait signal |> dropRepeats) signal

