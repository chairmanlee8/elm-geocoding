module Example where

import List
import Signal
import Signal (..)
import Time (..)
import Graphics.Element (Element)
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Http
import Window

import Geocoding
import Geocoding (showLongitude, showLatitude)

aLocation : Signal.Channel String
aLocation = Signal.channel ""

aExpandIndex : Signal.Channel Int
aExpandIndex = Signal.channel -1

viewResult : Bool -> Int -> Geocoding.Geocode -> Html
viewResult expand index gc =
    li 
        [ class (if expand then "expanded" else "")
        , onClick (Signal.send aExpandIndex index)
        ] 
        [ div
            [ class "coords" ]
            [ text (showLatitude gc.geometry.location)
            , br [] []
            , text (showLongitude gc.geometry.location) 
            ]
        , img
            [ src (if expand then Geocoding.mapUrl gc.geometry.location (Geocoding.calcZoom gc.geometry.viewport 600) (600, 160) else "") ]
            []
        ]

viewResults : Int -> List Geocoding.Geocode -> Html
viewResults expandIndex gcs = 
    ul 
        [ class "results" ] 
        (List.map (\(index, gc) -> viewResult (index==expandIndex) index gc) (List.map2 (,) [1..List.length gcs] gcs))

view : Int -> Geocoding.GeocodeResponse -> Html
view expandIndex resp =
    let resultHtml =
            case resp of 
                Geocoding.Success gcs -> viewResults expandIndex gcs
                Geocoding.Waiting -> div [ class "waiting" ] []
                Geocoding.Failure code -> span [ class "error" ] [ text (Geocoding.showStatus code) ]
    in
        div
            []
            [ input 
                [ class (if (Geocoding.isFailure resp) then "error" else "")
                , type' "text"
                , placeholder "Enter address or location..."
                , on "keyup" targetValue (Signal.send aLocation)
                ] 
                []
            , resultHtml
            ]

scene : (Int, Int) -> Int -> Geocoding.GeocodeResponse -> Element
scene (w, h) expandIndex gc = toElement w h (view expandIndex gc)

main : Signal Element
main = scene <~ Window.dimensions
              ~ subscribe aExpandIndex
              ~ merge (Geocoding.byAddress (Signal.map (\addr -> {address=addr}) (debounce (1 * second) (subscribe aLocation))))
                      (sampleOn (dropRepeats (subscribe aLocation)) (constant Geocoding.Waiting))

-- Rate-limiter
debounce : Time -> Signal a -> Signal a
debounce wait signal = sampleOn (since wait signal |> dropRepeats) signal

