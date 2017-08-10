module Map
    exposing
        ( Model
        , Msg
        , update
        , addMarkers
        , addMarker
        , initModel
        , Msg(..)
        , helsinkiLatLng
        , worldLatLng
        )

import Geolocation exposing (Location)
import Dict exposing (Dict)
import Data.Entry exposing (Entry, idToString)
import Task
import Util exposing (viewDate)
import Leaflet.Types exposing (LatLng, ZoomPanOptions, defaultZoomPanOptions, MarkerOptions, defaultMarkerOptions)
import Leaflet.Ports


type alias Model =
    { latLng : LatLng
    , zoomPanOptions : ZoomPanOptions
    , markers : Dict String ( LatLng, String )
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


worldLatLng : LatLng
worldLatLng =
    ( 0.0, 0.0 )


type Msg
    = SetLatLng ( LatLng, Int )
    | SetToCurrent (Result Geolocation.Error Location)
    | GoToCurrentLocation
    | GetCenter LatLng
    | AddMarker ( String, LatLng, String )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetLatLng ( latLng, zoom ) ->
            ( { model | latLng = latLng }
            , Leaflet.Ports.setView ( latLng, zoom, model.zoomPanOptions )
            )

        AddMarker ( id, latLng, popupText ) ->
            let
                newModel =
                    addMarkerToModel ( id, latLng, popupText ) model
            in
                ( newModel
                , Leaflet.Ports.setMarkers <| markersAsOutboundType newModel.markers
                )

        GetCenter latLng ->
            { model | latLng = latLng } ! []

        SetToCurrent (Ok { latitude, longitude }) ->
            update (SetLatLng ( ( latitude, longitude ), 12 )) model

        SetToCurrent (Err error) ->
            update (SetLatLng ( ( 0, 0 ), 1 )) model

        GoToCurrentLocation ->
            let
                geoTask =
                    Geolocation.now
                        |> Task.attempt SetToCurrent
            in
                model ! [ geoTask ]


addMarkerToModel : ( String, LatLng, String ) -> Model -> Model
addMarkerToModel ( id, latLng, popupText ) model =
    { model | markers = Dict.insert id ( latLng, popupText ) model.markers }


addMarkers : List Entry -> Cmd Msg
addMarkers entries =
    Cmd.batch <|
        List.map addMarker entries


addMarker : Entry -> Cmd Msg
addMarker entry =
    let
        { latitude, longitude } =
            entry.location

        popupText =
            makePopup entry
    in
        Task.perform
            (always
                (AddMarker
                    ( idToString entry.id
                    , ( latitude, longitude )
                    , popupText
                    )
                )
            )
            (Task.succeed ())


makePopup : Entry -> String
makePopup entry =
    "<div>"
        ++ entry.content
        ++ "</div>"
        ++ "<div>"
        ++ entry.translation
        ++ "</div>"
        ++ "<div>"
        ++ viewDate entry.addedAt
        ++ "</div>"


markersAsOutboundType : Dict String ( LatLng, String ) -> List ( String, LatLng, MarkerOptions, String )
markersAsOutboundType markers =
    Dict.toList markers
        |> List.map (\( id, ( latLng, popupText ) ) -> ( id, latLng, defaultMarkerOptions, popupText ))
