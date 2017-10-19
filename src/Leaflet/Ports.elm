port module Leaflet.Ports exposing (setView, toLeaflet)

import Leaflet.Types exposing (LatLng, ZoomPanOptions, MarkerOptions)
import Json.Encode exposing (Value)


port setView : ( LatLng, Int, ZoomPanOptions ) -> Cmd msg


port toLeaflet : Value -> Cmd msg
