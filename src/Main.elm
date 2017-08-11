module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (..)
import Views exposing (epButton)
import Http
import Data.Entry exposing (Entry)
import Request.Entry exposing (decodePouchEntries, decodePouchEntry)
import Page.Entry as Entry
import Map as Map
import Util exposing (viewDate)
import Pouch.Ports


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Pouch.Ports.getEntries (decodePouchEntries NewEntriesPouch)
        , Pouch.Ports.newEntry (decodePouchEntry NewEntryPouch)
        , Pouch.Ports.updatedEntry (decodePouchEntry UpdatedEntryPouch)
        ]



-- MODEL


type Page
    = Blank
    | Entry Entry.Model


type alias Model =
    { entries : List Entry
    , pageState : Page
    , mapState : Map.Model
    }


emptyModel : Model
emptyModel =
    { entries = []
    , pageState = Entry Entry.initNew
    , mapState = Map.initModel
    }


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Request.Entry.listPouch )



-- UPDATE


type Msg
    = NoOp
    | NewEntries (Result Http.Error (List Entry))
    | LoadEntries
    | LoadEntriesPouch
    | NewEntriesPouch (Result String (List Entry))
    | NewEntryPouch (Result String Entry)
    | UpdatedEntryPouch (Result String Entry)
    | EntryMsg Entry.Msg
    | MapMsg Map.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        -- Messages that exist for all "pages"
        NoOp ->
            model ! []

        NewEntries (Err err) ->
            model ! []

        NewEntries (Ok entries) ->
            { model | entries = entries } ! [ Cmd.map MapMsg (Map.addMarkers entries) ]

        NewEntriesPouch (Err err) ->
            model ! []

        NewEntriesPouch (Ok entries) ->
            { model | entries = entries } ! [ Cmd.map MapMsg (Map.addMarkers entries) ]

        NewEntryPouch (Err err) ->
            model ! []

        NewEntryPouch (Ok entry) ->
            let
                newEntries =
                    entry :: model.entries
            in
                { model | entries = newEntries } ! [ Cmd.map MapMsg (Map.addMarker entry) ]

        UpdatedEntryPouch (Err err) ->
            model ! []

        UpdatedEntryPouch (Ok entry) ->
            -- NOTE: not updating all fields atm, see Request.EditConfig
            let
                newEntries =
                    entry
                        :: List.filter (\e -> e.id /= entry.id) model.entries
            in
                { model | entries = newEntries } ! [ Cmd.map MapMsg (Map.addMarker entry) ]

        LoadEntries ->
            ( model, Http.send NewEntries Request.Entry.list )

        LoadEntriesPouch ->
            ( model, Pouch.Ports.listEntries "entry" )

        MapMsg msg ->
            -- more ad-hoc for Map messages, since we might want map to be co-located
            let
                ( newModel, newCmd ) =
                    Map.update msg model.mapState
            in
                ( { model | mapState = newModel }, Cmd.map MapMsg newCmd )

        -- Messages for another segment
        _ ->
            updatePage model.pageState msg model


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    -- More general function to abstract pages
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
    div [ class "pa3 ph5-ns bg-white" ]
        [ div [ class "mw7-ns center" ]
            [ div [ class "mv2 mv4-ns" ]
                [ viewFlight
                , viewPage model.pageState
                ]
            , div [ class "pt3" ]
                [ viewEntries model.entries
                ]
            ]
        ]


viewFlight : Html Msg
viewFlight =
    let
        classNames =
            "mr3 bg-beige-gray deep-blue pointer fw6 shadow-button"
    in
        div [ class "mb2 tc" ]
            [ epButton [ class classNames, onClick <| MapMsg (Map.SetLatLng ( Map.helsinkiLatLng, 12 )) ]
                [ text "Helsinki" ]
            , epButton [ class classNames, onClick <| MapMsg (Map.SetLatLng ( Map.worldLatLng, 1 )) ]
                [ text "World" ]
            , epButton [ class classNames, onClick <| MapMsg (Map.GoToCurrentLocation) ]
                [ text "Current" ]
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
    if entries /= [] then
        div [ class "dw" ] <| List.map viewEntry entries
    else
        div [ class "pa4 mb3 bg-lightest-blue tc f5" ]
            [ span [ class "dark-gray" ]
                [ text "Looks like you don't have any entries yet. Why don't you add one? :)"
                ]
            ]


viewEntry : Entry -> Html Msg
viewEntry entry =
    div
        [ class "dw-panel" ]
        [ div
            [ class "dw-panel__content bg-muted-blue mw5 center br4 pa4 shadow-card" ]
            [ div [ class "white tl" ]
                [ h2
                    [ class "mt0 mb2 f5 f4-ns fw6 overflow-hidden" ]
                    [ text entry.content ]
                , h2
                    [ class "mt0 f5 f4-ns fw6 overflow-hidden" ]
                    [ text entry.translation ]
                ]
            , hr
                [ class "w-100 mt4 mb3 bb bw1 b--black-10" ]
                []
            , div [ class "white f6 f5-ns" ]
                [ span [ class "db mb2 tr truncate" ] [ text <| viewDate entry.addedAt ]
                , span [ class "db mb1 tr truncate" ] [ text <| toString entry.location.latitude ++ ", " ]
                , span [ class "db tr truncate" ] [ text <| toString entry.location.longitude ]
                ]
            ]
        ]



-- viewEntryFlip : Entry -> Html Msg
-- viewEntryFlip entry =
--     div
--         [ class "dw-panel dw-flip dw-flip--md" ]
--         [ div
--             [ class "dw-panel__content dw-flip__content white" ]
--             [ div
--                 [ class "dw-flip__panel dw-flip__panel--front bg-muted-blue mw5 center br4 pa4 shadow-card" ]
--                 [ h2
--                     [ class "mt0 mb2 f5 f4-ns fw6 overflow-hidden" ]
--                     [ text entry.content ]
--                 , hr
--                     [ class "w-100 mt4 mb3 bb bw1 b--black-10" ]
--                     []
--                 , div [ class "near-white f6 f5-ns" ]
--                     [ span [ class "db mb2 tr truncate" ] [ text <| viewDate entry.addedAt ]
--                     , span [ class "db mb1 tr truncate" ] [ text <| toString entry.location.latitude ++ ", " ]
--                     , span [ class "db tr truncate" ] [ text <| toString entry.location.longitude ]
--                     ]
--                 ]
--             , div
--                 [ class "dw-flip__panel dw-flip__panel--back bg-light-blue mw5 center br4 pa4 shadow-card" ]
--                 [ h2
--                     [ class "mt0 f5 f4-ns fw6 overflow-hidden" ]
--                     [ text entry.translation ]
--                 ]
--             ]
--         ]
