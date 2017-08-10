module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (..)
import Http
import Data.Entry exposing (Entry)
import Request.Entry exposing (decodePouchEntries, decodePouchEntry)
import Page.Entry as Entry
import Map as Map
import Util exposing (viewDate)
import Pouch.Ports
import Json.Encode exposing (Value)
import Json.Decode as Decode


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

                nextId =
                    List.length model.entries
            in
                { model | entries = newEntries } ! [ Cmd.map MapMsg (Map.addMarker nextId entry) ]

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
                [ viewPage model.pageState
                ]
            , div [ class "pt3" ]
                [ viewEntries model.entries
                ]
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
    if entries /= [] then
        div [] <| List.map viewEntry entries
    else
        div [ class "pa4 mb3 bg-lightest-blue tc f5" ]
            [ span [ class "dark-gray" ]
                [ text "Looks like you don't have any entries yet. Why don't you add one? :)"
                ]
            ]


viewEntry : Entry -> Html Msg
viewEntry entry =
    div [ class "pa3 mb3 bg-lightest-blue near-black" ]
        [ span [ class "db mb1" ] [ text entry.content ]
        , span [ class "db mb1" ] [ text entry.translation ]
        , span [ class "db tr" ] [ text <| viewDate entry.addedAt ]
        , span [ class "db tr" ] [ text <| toString entry.location.longitude ++ ", " ++ toString entry.location.latitude ]
        , a [ class "dib link bb bw1 dark-gray pointer", onClick (EntryMsg (Entry.Edit entry)) ] [ text "edit" ]
        ]
