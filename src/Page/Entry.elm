module Page.Entry exposing (Model, Msg, initNew, update, view)

import Data.Entry as Entry exposing (Entry, EntryLocation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Http
import Request.Entry
import Date exposing (Date)
import Task


-- MODEL --


type alias Model =
    { errors : List Error
    , content : String
    , translation : String
    , location : EntryLocation
    , addedAt : Date
    }


initNew : Model
initNew =
    { errors = []
    , content = ""
    , translation = ""
    , location = initLocation
    , addedAt = Date.fromTime 0
    }


initLocation : EntryLocation
initLocation =
    { longitude = 0.0
    , latitude = 0.0
    , accuracy = 0
    }



-- UPDATE --


type Msg
    = Save
    | SetContent String
    | SetTranslation String
    | CreateCompleted (Result Http.Error Entry)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Save ->
            let
                reqTask addedAt =
                    Request.Entry.create { model | addedAt = addedAt }
                        |> Http.toTask

                getTimeAndSave =
                    Date.now
                        |> Task.andThen reqTask
                        |> Task.attempt CreateCompleted
            in
                ( model, getTimeAndSave )

        CreateCompleted (Ok article) ->
            model ! []

        CreateCompleted (Err error) ->
            { model | errors = model.errors ++ [ ( Form, "Server error while attempting to save note" ) ] } ! []

        SetContent content ->
            { model | content = content } ! []

        SetTranslation translation ->
            { model | translation = translation } ! []



-- VIEW --


view : Model -> Html Msg
view model =
    Html.form [ class "pa4 black-80", onSubmit Save ]
        [ fieldset [ class "measure ba b--transparent ph0 mh0" ]
            [ div []
                [ label [ class "f6 b db mv2", for "word" ] [ text "Word " ]
                , input
                    [ attribute "aria-describedby" "word-desc"
                    , class "input-reset ba b--black-20 pa2 mb2 db w-100"
                    , id "name"
                    , type_ "text"
                    , onInput SetContent
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
                    , onInput SetTranslation
                    ]
                    []
                , small [ class "f6 black-60 db mb2", id "translation-desc" ]
                    [ text "The translation for the word." ]
                ]
            , button [ class "f6 link dim ph3 pv2 mt3 mb2 dib white bg-dark-blue bw0" ]
                [ text "Save" ]
            ]
        ]



-- VALIDATION --


type Field
    = Form


type alias Error =
    ( Field, String )
