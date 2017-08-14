port module Leaflet.Ports exposing (setView, setMarkers, toLeaflet)

import Leaflet.Types exposing (LatLng, ZoomPanOptions, MarkerOptions)
import Json.Encode exposing (Value)


port setView : ( LatLng, Int, ZoomPanOptions ) -> Cmd msg


port setMarkers : List ( String, LatLng, MarkerOptions, String ) -> Cmd msg


port toLeaflet : Value -> Cmd msg
