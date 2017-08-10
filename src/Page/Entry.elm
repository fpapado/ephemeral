module Page.Entry exposing (Model, Msg, initNew, update, view, Msg(..))

import Data.Entry as Entry exposing (Entry, EntryLocation, EntryId)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Http
import Request.Entry
import Date exposing (Date)
import Task
import Geolocation exposing (Location)


-- MODEL --


type alias Model =
    { errors : List Error
    , content : String
    , translation : String
    , location : EntryLocation
    , addedAt : Date
    , editingEntry : Maybe EntryId
    }


initNew : Model
initNew =
    { errors = []
    , content = ""
    , translation = ""
    , location = initLocation
    , addedAt = Date.fromTime 0
    , editingEntry = Nothing
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
    | Commit
    | CommitPouch
    | Edit Entry
    | SetContent String
    | SetTranslation String
    | LocationFound (Result Geolocation.Error Location)
    | CreateCompleted (Result Http.Error Entry)
    | EditCompleted (Result Http.Error Entry)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Save ->
            case model.editingEntry of
                Nothing ->
                    let
                        getLocation =
                            Geolocation.now
                                |> Task.attempt LocationFound
                    in
                        ( model, getLocation )

                Just entryId ->
                    update CommitPouch model

        CommitPouch ->
            ( initNew
            , Request.Entry.createPouch model
            )

        Commit ->
            case model.editingEntry of
                Nothing ->
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

                Just eid ->
                    let
                        req =
                            Request.Entry.update eid model
                                |> Http.send EditCompleted
                    in
                        ( model, req )

        Edit entry ->
            { model
                | content = entry.content
                , translation = entry.translation
                , editingEntry = Just entry.id
            }
                ! []

        SetContent content ->
            { model | content = content } ! []

        SetTranslation translation ->
            { model | translation = translation } ! []

        LocationFound (Ok location) ->
            let
                entryLocation =
                    geoToEntryLocation location
            in
                update CommitPouch { model | location = entryLocation }

        LocationFound (Err error) ->
            { model | errors = model.errors ++ [ ( Form, "Geolocation error" ) ] } ! []

        CreateCompleted (Ok entry) ->
            initNew ! []

        CreateCompleted (Err error) ->
            { model | errors = model.errors ++ [ ( Form, "Server error while attempting to save note" ) ] } ! []

        EditCompleted (Ok entry) ->
            initNew ! []

        EditCompleted (Err error) ->
            { model | errors = model.errors ++ [ ( Form, "Server error while attempting to edit note" ) ] } ! []



-- VIEW --


view : Model -> Html Msg
view model =
    let
        isEditing =
            model.editingEntry /= Nothing

        saveButtonText =
            if isEditing then
                "Update"
            else
                "Save"
    in
        Html.form [ class "pa4 black-80", onSubmit Save ]
            [ fieldset [ class "measure ba b--transparent ph0 mh0" ]
                [ div []
                    [ label [ class "f6 b db mv2", for "word" ] [ text "Word " ]
                    , input
                        [ attribute "aria-describedby" "word-desc"
                        , value model.content
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
                        , value model.translation
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
                    [ text saveButtonText ]
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


viewIf : Bool -> Html msg -> Html msg
viewIf condition content =
    if condition then
        content
    else
        Html.text ""



-- VALIDATION --


type Field
    = Form


type alias Error =
    ( Field, String )



-- UTIL --


geoToEntryLocation : Location -> EntryLocation
geoToEntryLocation { latitude, longitude, accuracy } =
    EntryLocation latitude longitude accuracy
