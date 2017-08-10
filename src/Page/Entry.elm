module Page.Entry exposing (Model, Msg, initNew, update, view, Msg(..))

import Data.Entry as Entry exposing (Entry, EntryLocation, EntryId)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Http
import Views exposing (formField, epButton)
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
    , editingEntry : Maybe ( EntryId, String )
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


initGeoLocation : Location
initGeoLocation =
    { accuracy = 0.0
    , altitude = Just { value = 0.0, accuracy = 0.0 }
    , latitude = 0.0
    , longitude = 0.0
    , movement = Just Geolocation.Static
    , timestamp = 0
    }



-- UPDATE --


type Msg
    = Save
    | CommitPouch
    | Edit Entry
    | SetContent String
    | SetTranslation String
    | SetLocationTime (Result Geolocation.Error ( Location, Date ))
    | SetWithNullLoc ( EntryLocation, Date )
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
                                |> Task.onError (\err -> Task.succeed initGeoLocation)

                        getTime a =
                            Date.now
                                |> Task.andThen (\b -> Task.succeed ( a, b ))

                        seq =
                            getLocation
                                |> Task.andThen getTime
                                |> Task.attempt SetLocationTime
                    in
                        ( model, seq )

                Just ( entryId, rev ) ->
                    update CommitPouch model

        CommitPouch ->
            case model.editingEntry of
                Nothing ->
                    ( initNew, Request.Entry.createPouch model )

                Just ( eid, rev ) ->
                    -- ( initNew, Request.Entry.updatePouch model )
                    ( initNew, Request.Entry.updatePouch eid rev model )

        Edit entry ->
            { model
                | content = entry.content
                , translation = entry.translation
                , editingEntry = Just ( entry.id, entry.rev )
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
                { model | location = entryLocation } ! []

        LocationFound (Err error) ->
            { model | errors = model.errors ++ [ ( Form, "Geolocation error" ) ] } ! []

        SetLocationTime (Ok ( location, addedAt )) ->
            let
                entryLocation =
                    geoToEntryLocation location

                newModel =
                    { model
                        | location = entryLocation
                        , addedAt = addedAt
                    }
            in
                update CommitPouch newModel

        SetLocationTime (Err error) ->
            { model | errors = model.errors ++ [ ( Form, viewGeoError error ) ] } ! []

        SetWithNullLoc ( location, addedAt ) ->
            let
                newModel =
                    { model
                        | location = location
                        , addedAt = addedAt
                    }
            in
                update CommitPouch newModel

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
        Html.form [ class "black-80", onSubmit Save ]
            [ fieldset [ class "measure ba b--transparent ph0 mh0 center" ]
                [ formField model.content SetContent "word" "Word" "text" "The word to save."
                , formField model.translation SetTranslation "translation" "Translation" "text" "The translation for the word."
                , epButton [ class "w-100" ] [ text saveButtonText ]
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


viewGeoError : Geolocation.Error -> String
viewGeoError error =
    case error of
        Geolocation.PermissionDenied string ->
            "Permission Denied"

        Geolocation.LocationUnavailable string ->
            "Location Unavailable"

        Geolocation.Timeout string ->
            "Location Search Timed Out"
