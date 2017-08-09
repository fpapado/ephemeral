module Page.Entry exposing (Model, Msg, initNew, update, view)

import Data.Entry as Entry exposing (Entry, EntryLocation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


-- MODEL --


type alias Model =
    { content : String
    , translation : String
    , location : EntryLocation
    }


initNew : Model
initNew =
    { content = ""
    , translation = ""
    , location = initLocation
    }


initLocation : EntryLocation
initLocation =
    { longitude = 0.0
    , latitude = 0.0
    , accuracy = 0
    }



-- UPDATE --


type Msg
    = SetContent String
    | SetTranslation String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetContent content ->
            { model | content = content } ! []

        SetTranslation translation ->
            { model | translation = translation } ! []



-- VIEW --


view : Html Msg
view =
    Html.form [ class "pa4 black-80" ]
        [ div [ class "measure" ]
            [ div []
                [ label [ class "f6 b db mb2", for "word" ] [ text "Word " ]
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
                    , onInput SetContent
                    ]
                    []
                , small [ class "f6 black-60 db mb2", id "translation-desc" ]
                    [ text "The translation for the word." ]
                ]
            ]
        ]
