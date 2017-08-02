module Main exposing (..)

import Html exposing (..)
import Time exposing (Time)


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


type alias Entry =
    { description : String
    , completed : Bool
    , editing : Bool
    , location : NoteLocation
    , id : Int
    }


type alias NoteLocation =
    { latitude : Float
    , longitude : Float
    , accuracy : Float
    , timestamp : Time
    }


emptyLocation : NoteLocation
emptyLocation =
    { latitude = 0.0, longitude = 0.0, accuracy = 0.0, timestamp = 0.0 }


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



-- How we update our Model on a given Msg?


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []



-- VIEW


view : Model -> Html Msg
view model =
    div [] []
