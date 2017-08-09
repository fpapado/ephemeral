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


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { entries : List Entry
    , entryInput : { content : String, translation : String }
    }


emptyModel : Model
emptyModel =
    { entries = []
    , entryInput = { content = "", translation = "" }
    }


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Http.send NewEntries Request.Entry.list )



-- UPDATE


{-| Users of our app can trigger messages by clicking and typing. These
messages are fed into the `update` function as they occur, letting us react
to them.
-}
type Msg
    = NoOp
    | NewEntries (Result Http.Error (List Entry))
    | LoadEntries
    | EditContent String
    | EditTranslation String



-- How we update our Model on a given Msg?


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        NewEntries (Err err) ->
            model ! []

        NewEntries (Ok entries) ->
            { model | entries = entries } ! []

        LoadEntries ->
            ( model, Http.send NewEntries Request.Entry.list )

        EditContent str ->
            let
                ei =
                    model.entryInput

                newInput =
                    { ei | content = str }
            in
                { model | entryInput = newInput } ! []

        EditTranslation str ->
            let
                ei =
                    model.entryInput

                newInput =
                    { ei | translation = str }
            in
                { model | entryInput = newInput } ! []



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "pa5 min-vh-100 bg-white" ]
        [ div [ class "mw7-ns center" ]
            [ viewWordInput
            , viewEntries model.entries
            , button [ onClick LoadEntries ] [ text "Fetch Entries" ]
            ]
        ]


viewWordInput : Html Msg
viewWordInput =
    Html.form [ class "pa4 black-80" ]
        [ div [ class "measure" ]
            [ div []
                [ label [ class "f6 b db mb2", for "word" ] [ text "Word " ]
                , input
                    [ attribute "aria-describedby" "word-desc"
                    , class "input-reset ba b--black-20 pa2 mb2 db w-100"
                    , id "name"
                    , type_ "text"
                    , onInput EditContent
                    ]
                    []
                , small [ class "f6 black-60 db mb2", id "word-desc" ]
                    [ text "The word to save." ]
                ]
            , div [ class "mt3" ]
                [ label [ class "f6 b db mb2", for "translation" ] [ text "Translation " ]
                , input
                    [ attribute "aria-describedby" "tranlsation-desc"
                    , class "input-reset ba b--black-20 pa2 mb2 db w-100"
                    , id "name"
                    , type_ "text"
                    , onInput EditTranslation
                    ]
                    []
                , small [ class "f6 black-60 db mb2", id "translation-desc" ]
                    [ text "The translation for the word." ]
                ]
            ]
        ]


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
