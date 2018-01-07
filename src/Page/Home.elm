module Page.Home exposing (Model, init, update, view, Msg(..), subscriptions)

import Html exposing (..)
import Html.Keyed
import Html.Lazy exposing (lazy, lazy2)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (..)
import Views.General exposing (epButton, avatar)
import Util exposing (viewDate, viewIf)
import Dict exposing (Dict)
import Map as Map
import Pouch.Ports
import Data.Entry exposing (Entry, EntryId, idToString)
import Data.Session exposing (Session)
import Request.Entry exposing (decodePouchEntries, decodePouchEntry, decodeDeletedEntry)


type alias Model =
    { entries : Dict String Entry
    , mapState : Map.Model
    }


init : Model
init =
    { entries = Dict.empty
    , mapState = Map.initModel
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Pouch.Ports.getEntries (decodePouchEntries NewEntries)
        , Pouch.Ports.updatedEntry (decodePouchEntry NewEntry)
        , Pouch.Ports.deletedEntry (decodeDeletedEntry DeletedEntry)
        ]


type Msg
    = LoadEntries
    | ExportCardsCsv
    | ExportCardsAnki
    | DeleteEntry EntryId
    | NewEntries (List Entry)
    | NewEntry (Result String Entry)
    | DeletedEntry (Result String EntryId)
    | MapMsg Map.Msg


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        LoadEntries ->
            ( model, Pouch.Ports.listEntries "entry" )

        ExportCardsCsv ->
            model ! [ Pouch.Ports.exportCards "CSV" ]

        ExportCardsAnki ->
            model ! [ Pouch.Ports.exportCards "ANKI" ]

        DeleteEntry entryId ->
            model ! [ Request.Entry.delete entryId ]

        NewEntries entries ->
            let
                assocList =
                    List.map (\e -> ( idToString e.id, e )) entries

                newEntries =
                    Dict.fromList (assocList)
            in
                { model | entries = newEntries } ! [ Cmd.map MapMsg (Map.addMarkers entries) ]

        NewEntry (Err err) ->
            model ! []

        NewEntry (Ok entry) ->
            let
                newEntries =
                    Dict.insert (idToString entry.id) entry model.entries
            in
                { model | entries = newEntries } ! [ Cmd.map MapMsg (Map.addMarkers [ entry ]) ]

        DeletedEntry (Err err) ->
            model ! []

        DeletedEntry (Ok entryId) ->
            let
                newEntries =
                    Dict.remove (idToString entryId) model.entries

                ( newMapState, newMapCmd ) =
                    Map.update (Map.RemoveMarker entryId) model.mapState
            in
                ( { model
                    | entries = newEntries
                    , mapState = newMapState
                  }
                , Cmd.map MapMsg newMapCmd
                )

        MapMsg msg ->
            -- more ad-hoc for Map messages, since we might want map to be co-located
            let
                ( newModel, newCmd ) =
                    Map.update msg model.mapState
            in
                ( { model | mapState = newModel }, Cmd.map MapMsg newCmd )


view : Model -> Html Msg
view model =
    div []
        [ div [ class "mb2 mb4-ns" ]
            [ viewFlight
            , div [ class "measure center mt3" ]
                [ epButton [ class "db mb3 w-100 white bg-deep-blue", onClick ExportCardsCsv ] [ text "Export CSV (offline)" ]
                , epButton [ class "db w-100 white bg-deep-blue", onClick ExportCardsAnki ] [ text "Export Anki (online)" ]
                ]
            ]
        , div [ class "pt3" ]
            [ lazy viewEntries (Dict.toList model.entries)
            ]
        ]


viewFlight : Html Msg
viewFlight =
    let
        classNames =
            "mr3 bg-beige-gray deep-blue pointer fw6 shadow-button"
    in
        div [ class "mb4 tc" ]
            [ epButton [ class classNames, onClick <| MapMsg (Map.SetLatLng ( Map.helsinkiLatLng, 12 )) ]
                [ text "Helsinki" ]
            , epButton [ class classNames, onClick <| MapMsg (Map.GoToCurrentLocation) ]
                [ text "Current" ]
            , epButton [ class classNames, onClick <| MapMsg (Map.SetLatLng ( Map.worldLatLng, 1 )) ]
                [ text "World" ]
            ]


viewEntries : List ( String, Entry ) -> Html Msg
viewEntries keyedEntries =
    if keyedEntries /= [] then
        Html.Keyed.node "div" [ class "dw" ] <| List.map (\( id, entry ) -> ( id, lazy viewEntry entry )) keyedEntries
    else
        div [ class "pa4 mb3 bg-main-blue br1 tc f5" ]
            [ p [ class "dark-gray lh-copy" ]
                [ text "Looks like you don't have any entries yet. Why don't you add one? :)"
                ]
            ]


viewEntry : Entry -> Html Msg
viewEntry entry =
    div
        [ class "dw-panel" ]
        [ div
            [ class "dw-panel__content bg-muted-blue mw5 center br4 pa4 shadow-card" ]
            [ a [ onClick <| DeleteEntry entry.id, class "close handwriting black-70 hover-white" ] [ text "×" ]
            , div [ class "white tl" ]
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
