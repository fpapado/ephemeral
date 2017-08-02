module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Http
import Data.Entry exposing (Entry)
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
    }


emptyModel : Model
emptyModel =
    { entries = []
    }


init : ( Model, Cmd Msg )
init =
    emptyModel ! []



-- UPDATE


{-| Users of our app can trigger messages by clicking and typing. These
messages are fed into the `update` function as they occur, letting us react
to them.
-}
type Msg
    = NoOp
    | NewEntries (Result Http.Error (List Entry))
    | LoadEntries



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



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewEntries model.entries
        , button [ onClick LoadEntries ] [ text "Fetch Entries" ]
        ]


viewEntries : List Entry -> Html Msg
viewEntries entryList =
    div [] [ Html.text <| toString entryList ]
