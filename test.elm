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

view : Geocoding.GeocodeResponse -> Html
view resp =
    let resultStr = 
            case resp of 
                Geocoding.Success gcs ->
                    if (length gcs > 0)
                        then let gc = head gcs in "Lat " ++ (show gc.geometry.location.lat) ++ ", Lng " ++ (show gc.geometry.location.lng)
                        else "No results"

                Geocoding.Waiting -> "Waiting"
                _ -> "Error"
    in
        div
            []
            [ input [ type' "text", placeholder "Enter address or location...", on "keyup" getValue aLocation.handle identity ] []
            , div [] [ text resultStr ]
            ]

scene : (Int, Int) -> Geocoding.GeocodeResponse -> Element
scene (w, h) gc = toElement w h (view gc)

main : Signal Element
main = scene <~ Window.dimensions
              ~ Geocoding.byAddress (lift (\addr -> {address=addr}) (debounce (1 * second) aLocation.signal))

-- Rate-limiter
debounce : Time -> Signal a -> Signal a
debounce wait signal = sampleOn (since wait signal |> dropRepeats) signal

