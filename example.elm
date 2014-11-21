module Example where

import Time (..)
import Graphics.Input as Input
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Http
import Window

import Geocoding
import Geocoding (showLongitude, showLatitude)

aLocation : Input.Input String
aLocation = Input.input ""

aExpandIndex : Input.Input Int
aExpandIndex = Input.input -1

viewResult : Bool -> Int -> Geocoding.Geocode -> Html
viewResult expand index gc =
    li 
        [ class (if expand then "expanded" else "")
        , on "click" getAnything aExpandIndex.handle (\_ -> index)
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

viewResults : Int -> [Geocoding.Geocode] -> Html
viewResults expandIndex gcs = 
    ul 
        [ class "results" ] 
        (map (\(index, gc) -> viewResult (index==expandIndex) index gc) (zip [1..length gcs] gcs))

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
                , on "keyup" getValue aLocation.handle identity 
                ] 
                []
            , resultHtml
            ]

scene : (Int, Int) -> Int -> Geocoding.GeocodeResponse -> Element
scene (w, h) expandIndex gc = toElement w h (view expandIndex gc)

main : Signal Element
main = scene <~ Window.dimensions
              ~ aExpandIndex.signal
              ~ merge (Geocoding.byAddress (lift (\addr -> {address=addr}) (debounce (1 * second) aLocation.signal)))
                      (sampleOn (dropRepeats aLocation.signal) (constant Geocoding.Waiting))

-- Rate-limiter
debounce : Time -> Signal a -> Signal a
debounce wait signal = sampleOn (since wait signal |> dropRepeats) signal

