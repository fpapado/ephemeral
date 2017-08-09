module Map exposing (Model, Msg, update, addMarkers, initModel, Msg(..), addMarker)

import Dict exposing (Dict)
import Task
import Util exposing (viewDate)
import Data.Entry exposing (Entry)
import Leaflet.Types exposing (LatLng, ZoomPanOptions, defaultZoomPanOptions, MarkerOptions, defaultMarkerOptions)
import Leaflet.Ports


type alias Model =
    { latLng : LatLng
    , zoomPanOptions : ZoomPanOptions
    , markers : Dict Int ( LatLng, String )
    }


initModel : Model
initModel =
    { latLng = helsinkiLatLng
    , zoomPanOptions = defaultZoomPanOptions
    , markers = Dict.empty
    }


helsinkiLatLng : LatLng
helsinkiLatLng =
    ( 60.1719, 24.9414 )


type Msg
    = SetLatLng LatLng
    | GetCenter LatLng
    | AddMarker ( Int, LatLng, String )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetLatLng latLng ->
            ( { model | latLng = latLng }
            , Leaflet.Ports.setView ( latLng, 13, model.zoomPanOptions )
            )

        AddMarker ( id, latLng, popupText ) ->
            let
                newModel =
                    addMarker ( id, latLng, popupText ) model
            in
                ( newModel
                , Leaflet.Ports.setMarkers <| markersAsOutboundType newModel.markers
                )

        GetCenter latLng ->
            { model | latLng = latLng } ! []


addMarker : ( Int, LatLng, String ) -> Model -> Model
addMarker ( id, latLng, popupText ) model =
    { model | markers = Dict.insert id ( latLng, popupText ) model.markers }


addMarkers : List Entry -> Cmd Msg
addMarkers entries =
    Cmd.batch <|
        List.indexedMap addMarkerCmd entries


addMarkerCmd : Int -> Entry -> Cmd Msg
addMarkerCmd id_ entry =
    Task.perform
        (always
            (AddMarker
                ( id_
                , ( entry.location.latitude, entry.location.longitude )
                , entry.content
                    ++ "\n"
                    ++ entry.translation
                    ++ "\n"
                    ++ viewDate entry.addedAt
                )
            )
        )
        (Task.succeed ())


markersAsOutboundType : Dict Int ( LatLng, String ) -> List ( Int, LatLng, MarkerOptions, String )
markersAsOutboundType markers =
    Dict.toList markers
        |> List.map (\( id, ( latLng, popupText ) ) -> ( id, latLng, defaultMarkerOptions, popupText ))
