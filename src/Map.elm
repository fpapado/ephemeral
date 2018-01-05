module Map
    exposing
        ( Model
        , Msg
        , update
        , addMarkers
        , initModel
        , Msg(..)
        , helsinkiLatLng
        , worldLatLng
        )

import Geolocation exposing (Location)
import Dict exposing (Dict)
import Data.Entry exposing (Entry, EntryId, idToString)
import Task
import Json.Encode
import Util exposing (viewDate)
import Leaflet.Types
    exposing
        ( LatLng
        , ZoomPanOptions
        , defaultZoomPanOptions
        , MarkerOptions
        , defaultMarkerOptions
        , encodeMarkerOptions
        , encodeZoomPanOptions
        , encodeLatLng
        )
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
    | AddMarkers (List ( String, LatLng, String ))
    | RemoveMarker EntryId


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetLatLng ( latLng, zoom ) ->
            ( { model | latLng = latLng }
            , encodeSetView ( latLng, zoom, model.zoomPanOptions ) |> Leaflet.Ports.toLeaflet
            )

        AddMarkers markers ->
            let
                newModel =
                    addMarkersToModel markers model
            in
                ( newModel, encodeMarkers newModel.markers |> encodeSetMarkers |> Leaflet.Ports.toLeaflet )

        RemoveMarker entryId ->
            let
                newMarkers =
                    Dict.remove (idToString entryId) model.markers
            in
                ( { model | markers = newMarkers }, encodeRemoveMarker entryId |> Leaflet.Ports.toLeaflet )

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


addMarkersToModel : List ( String, LatLng, String ) -> Model -> Model
addMarkersToModel markers model =
    let
        addMarker ( id, latLng, popupText ) dict =
            Dict.insert id ( latLng, popupText ) dict

        newMarkers =
            List.foldl addMarker model.markers markers
    in
        { model | markers = newMarkers }


addMarkers : List Entry -> Cmd Msg
addMarkers entries =
    let
        markers =
            List.map entryToMarker entries
    in
        Task.perform
            (always
                (AddMarkers markers)
            )
            (Task.succeed ())


entryToMarker : Entry -> ( String, LatLng, String )
entryToMarker entry =
    let
        { latitude, longitude } =
            entry.location

        popupText =
            makePopup entry
    in
        ( idToString entry.id
        , ( latitude, longitude )
        , popupText
        )


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


encodeMarkers : Dict String ( LatLng, String ) -> List Json.Encode.Value
encodeMarkers markers =
    Dict.toList markers
        |> List.map
            (\( id, ( latLng, popupText ) ) ->
                Json.Encode.object
                    [ ( "id", Json.Encode.string id )
                    , ( "latLng", encodeLatLng latLng )
                    , ( "markerOptions", encodeMarkerOptions defaultMarkerOptions )
                    , ( "popupText", Json.Encode.string popupText )
                    ]
            )


encodeSetView : ( LatLng, Int, ZoomPanOptions ) -> Json.Encode.Value
encodeSetView ( latLng, zoom, opts ) =
    Json.Encode.object
        [ ( "type", Json.Encode.string "SetView" )
        , ( "data"
          , Json.Encode.object
                [ ( "center", encodeLatLng latLng )
                , ( "zoom", Json.Encode.int zoom )
                , ( "options", encodeZoomPanOptions opts )
                ]
          )
        ]


encodeSetMarkers : List Json.Encode.Value -> Json.Encode.Value
encodeSetMarkers markers =
    Json.Encode.object
        [ ( "type", Json.Encode.string "SetMarkers" )
        , ( "data", Json.Encode.list markers )
        ]


encodeRemoveMarker : EntryId -> Json.Encode.Value
encodeRemoveMarker entryId =
    Json.Encode.object
        [ ( "type", Json.Encode.string "RemoveMarker" )
        , ( "data", Json.Encode.string <| idToString entryId )
        ]
