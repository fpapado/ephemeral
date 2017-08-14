port module Leaflet.Ports exposing (setView, setMarkers)

import Leaflet.Types exposing (LatLng, ZoomPanOptions, MarkerOptions)


port setView : ( LatLng, Int, ZoomPanOptions ) -> Cmd msg


port setMarkers : List ( String, LatLng, MarkerOptions, String ) -> Cmd msg
