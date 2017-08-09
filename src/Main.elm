module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (..)
import Http
import Dict exposing (Dict)
import Data.Entry exposing (Entry)
import Date exposing (Date)
import Date.Extra.Config.Config_en_gb exposing (config)
import Date.Extra.Format exposing (format)
import Request.Entry
import Page.Entry as Entry
import Leaflet.Types exposing (LatLng, ZoomPanOptions, defaultZoomPanOptions, MarkerOptions, defaultMarkerOptions)
import Leaflet.Ports


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always <| Leaflet.Ports.getCenter GetCenter
        }



-- MODEL


type Page
    = Blank
    | Entry Entry.Model


type alias Model =
    { entries : List Entry
    , pageState : Page
    , latLng : LatLng
    , zoomPanOptions : ZoomPanOptions
    , markers : Dict Int ( LatLng, String )
    }


emptyModel : Model
emptyModel =
    { entries = []
    , pageState = Entry Entry.initNew
    , latLng = helsinkiLatLng
    , zoomPanOptions = defaultZoomPanOptions
    , markers = Dict.empty
    }


helsinkiLatLng : LatLng
helsinkiLatLng =
    ( 60.192059, 24.945831 )


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Http.send NewEntries Request.Entry.list )



-- UPDATE


type Msg
    = NoOp
    | NewEntries (Result Http.Error (List Entry))
    | LoadEntries
    | SetLatLng LatLng
    | GetCenter LatLng
    | EntryMsg Entry.Msg
    | AddMarker ( Int, LatLng, String )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Messages that exist for all "pages"
        NoOp ->
            model ! []

        NewEntries (Err err) ->
            model ! []

        NewEntries (Ok entries) ->
            { model | entries = entries } ! []

        LoadEntries ->
            ( model, Http.send NewEntries Request.Entry.list )

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

        -- Messages for another segment
        _ ->
            updatePage model.pageState msg model


addMarker : ( Int, LatLng, String ) -> Model -> Model
addMarker ( id, latLng, popupText ) model =
    { model | markers = Dict.insert id ( latLng, popupText ) model.markers }


markersAsOutboundType : Dict Int ( LatLng, String ) -> List ( Int, LatLng, MarkerOptions, String )
markersAsOutboundType markers =
    Dict.toList markers
        |> List.map (\( id, ( latLng, popupText ) ) -> ( id, latLng, defaultMarkerOptions, popupText ))


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    let
        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
                ( { model | pageState = (toModel newModel) }, Cmd.map toMsg newCmd )
    in
        case ( msg, page ) of
            ( EntryMsg subMsg, Entry subModel ) ->
                toPage Entry EntryMsg (Entry.update) subMsg subModel

            ( _, Blank ) ->
                -- Disregard messages for Blank page/segment
                model ! []

            ( _, _ ) ->
                -- Disregard messages for wrong page/segment
                model ! []



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "pa5 min-vh-100 bg-white" ]
        [ div [ class "mw7-ns center" ]
            [ viewPage model.pageState
            , button [ onClick LoadEntries ] [ text "Fetch Entries" ]
            , button [ onClick <| SetLatLng helsinkiLatLng ] [ text "Locate Helsinki" ]
            , button [ onClick <| AddMarker ( 1, helsinkiLatLng, "Helsinki, FI" ) ] [ text "Pin Helsinki" ]
            , viewEntries model.entries
            ]
        ]


viewPage : Page -> Html Msg
viewPage page =
    -- Pass things to page's view
    case page of
        Blank ->
            Html.text ""

        Entry subModel ->
            Entry.view subModel
                |> Html.map EntryMsg


viewEntries : List Entry -> Html Msg
viewEntries entries =
    div [] <| List.map viewEntry entries


viewEntry : Entry -> Html Msg
viewEntry entry =
    div [ class "pa3 mb3 bg-light-blue" ]
        [ span [ class "db mb1" ] [ text entry.content ]
        , span [ class "db mb1" ] [ text entry.translation ]
        , span [ class "db tr" ] [ text <| viewDate entry.addedAt ]
        , span [ class "db tr" ] [ text <| toString entry.location.longitude ++ ", " ++ toString entry.location.latitude ]
        , a [ class "dib link bb bw2 white pointer", onClick (EntryMsg (Entry.Edit entry)) ] [ text "edit" ]
        ]


viewDate : Date -> String
viewDate date =
    format config config.format.dateTime date
