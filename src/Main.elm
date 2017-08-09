module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (..)
import Http
import Data.Entry exposing (Entry)
import Date exposing (Date)
import Date.Extra.Config.Config_en_gb exposing (config)
import Date.Extra.Format exposing (format)
import Request.Entry
import Page.Entry as Entry


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
    }


emptyModel : Model
emptyModel =
    { entries = []
    , pageState = Entry Entry.initNew
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

        -- Messages for another segment
        _ ->
            updatePage model.pageState msg model


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
            , viewEntries model.entries
            , button [ onClick LoadEntries ] [ text "Fetch Entries" ]
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
        ]


viewDate : Date -> String
viewDate date =
    format config config.format.dateTime date
