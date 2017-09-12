module Page.Login exposing (ExternalMsg(..), Model, Msg, initialModel, update, view, decodeLogin, decodeLogout, logout)

import Data.User as User exposing (User)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Validate exposing (..)
import Views.General as Views exposing (formField, epButton)
import Util exposing (viewIf)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Json.Decode.Pipeline as P exposing (decode, required)
import Pouch.Ports


-- MODEL --
-- Could also have a Data.User and Data.Session later on


type alias Model =
    { errors : List Error
    , username : String
    , password : String
    }


initialModel : Model
initialModel =
    { errors = []
    , username = ""
    , password = ""
    }



--  Could factor out


type alias LoginConfig record =
    { record
        | username : String
        , password : String
    }


login : LoginConfig record -> Cmd msg
login config =
    let
        login =
            Encode.object
                [ ( "username", Encode.string config.username )
                , ( "password", Encode.string config.password )
                ]
    in
        Pouch.Ports.sendLogin login


logout : Cmd msg
logout =
    Pouch.Ports.sendLogout ""


decodeLogin : (Result String User -> msg) -> Value -> msg
decodeLogin toMsg user =
    let
        result =
            Decode.decodeValue decodeUser user
    in
        toMsg result


decodeLogout : (Result String Bool -> msg) -> Value -> msg
decodeLogout toMsg res =
    let
        decodeRes =
            decode identity
                |> P.required "ok" Decode.bool

        result =
            Decode.decodeValue decodeRes res
    in
        toMsg result


decodeUser : Decoder User
decodeUser =
    decode User
        |> P.required "username" Decode.string



-- UPDATE --


type Msg
    = SubmitForm
    | SetUsername String
    | SetPassword String
    | LoginCompleted (Result String User)


type ExternalMsg
    = NoOp
    | SetUser User


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        SubmitForm ->
            case validate model of
                [] ->
                    ( ( { model | errors = [] }
                      , login model
                      )
                    , NoOp
                    )

                errors ->
                    ( ( { model | errors = errors }, Cmd.none ), NoOp )

        SetUsername username ->
            ( ( { model | username = username }, Cmd.none ), NoOp )

        SetPassword password ->
            ( ( { model | password = password }, Cmd.none ), NoOp )

        LoginCompleted (Err error) ->
            ( ( { model | errors = [ ( Form, error ) ] }, Cmd.none ), NoOp )

        LoginCompleted (Ok user) ->
            ( ( model, Cmd.none )
            , SetUser user
            )


view : Model -> Html Msg
view model =
    Html.form [ class "black-80", onSubmit SubmitForm ]
        [ fieldset [ class "measure ba b--transparent pa0 ma0 center" ]
            [ p [ class "lh-copy f5 mb3 black-80" ] [ text "Logging in allows automatic syncing of your files to a remote database. Files on your device are persisted between visits even without logging in, but you might want the backup. Currently, signups are not active, but we're working on it! Click on the Guest label to go back to the note form." ]
            , formField model.username SetUsername "username" "Username" "text" "Your username."
            , formField model.password SetPassword "password" "Password" "password" "Your password."
            , epButton [ class "w-100 white bg-deep-blue" ] [ text "Log In" ]
            , viewIf (model.errors /= []) (viewErrors model.errors)
            ]
        ]


viewErrors : List Error -> Html Msg
viewErrors errors =
    let
        viewError ( field, err ) =
            span [ class "db mb2" ] [ text err ]
    in
        div [ class "mt2 pa3 f5 bg-light-red white" ] <|
            List.map viewError errors



-- VALIDATION --


type Field
    = Form
    | Username
    | Password


type alias Error =
    ( Field, String )


validate : Model -> List Error
validate =
    Validate.all
        [ .username >> ifBlank ( Username, "email can't be blank." )
        , .password >> ifBlank ( Password, "password can't be blank." )
        ]
