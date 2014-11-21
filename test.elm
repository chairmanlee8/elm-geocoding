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
import Geocoding (showLongitude, showLatitude)

aLocation : Input.Input String
aLocation = Input.input ""

viewResult : Geocoding.Geocode -> Html
viewResult gc =
    li [] 
        [ text (showLatitude gc.geometry.location)
        , br [] []
        , text (showLongitude gc.geometry.location) 
        ]

viewResults : [Geocoding.Geocode] -> Html
viewResults gcs = ul [ class "results" ] (map viewResult gcs)

view : Geocoding.GeocodeResponse -> Html
view resp =
    let resultHtml =
            case resp of 
                Geocoding.Success gcs -> viewResults gcs
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

scene : (Int, Int) -> Geocoding.GeocodeResponse -> Element
scene (w, h) gc = toElement w h (view gc)

main : Signal Element
main = scene <~ Window.dimensions
              ~ merge (Geocoding.byAddress (lift (\addr -> {address=addr}) (debounce (1 * second) aLocation.signal)))
                      (sampleOn (dropRepeats aLocation.signal) (constant Geocoding.Waiting))

-- Rate-limiter
debounce : Time -> Signal a -> Signal a
debounce wait signal = sampleOn (since wait signal |> dropRepeats) signal

