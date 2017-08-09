module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (..)
import Http
import Data.Entry exposing (Entry)
import Date exposing (Date)
import Request.Entry
import Page.Entry as Entry
import Map as Map
import Util exposing (viewDate)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



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
    ( emptyModel, Http.send NewEntries Request.Entry.list )



-- UPDATE


type Msg
    = NoOp
    | NewEntries (Result Http.Error (List Entry))
    | LoadEntries
    | EntryMsg Entry.Msg
    | MapMsg Map.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Messages that exist for all "pages"
        NoOp ->
            model ! []

        NewEntries (Err err) ->
            model ! []

        NewEntries (Ok entries) ->
            { model | entries = entries } ! [ Cmd.map MapMsg (Map.addMarkers entries) ]

        LoadEntries ->
            ( model, Http.send NewEntries Request.Entry.list )

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
    div [ class "pa5 min-vh-100 bg-white" ]
        [ div [ class "mw7-ns center" ]
            [ viewPage model.pageState
            , button [ onClick LoadEntries ] [ text "Fetch Entries" ]
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
