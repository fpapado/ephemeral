module Page.FullMap exposing (Model, Msg, update, view)

import Geolocation exposing (Location)
import Task
import Map exposing (setView)
import Html exposing (Html, main_, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Views.General exposing (epButton)
import Leaflet.Types exposing (LatLng)
import Util exposing ((=>))


-- VIEW --


type Msg
    = SetView ( LatLng, Int )
    | GoToCurrentLocation
    | SetToCurrent (Result Geolocation.Error Location)


type alias Model =
    {}


view : Html Msg
view =
    main_ [] [ viewDestinationButtons ]



-- TODO: This is kind of silly, and should be fixed once we make Map top-level


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetView ( latLng, zoom ) ->
            model => setView ( latLng, zoom )

        SetToCurrent (Ok { latitude, longitude }) ->
            model => setView ( ( latitude, longitude ), 14 )

        SetToCurrent (Err error) ->
            model => Cmd.none

        GoToCurrentLocation ->
            let
                geoTask =
                    Geolocation.now
                        |> Task.attempt SetToCurrent
            in
                model ! [ geoTask ]


viewDestinationButtons : Html Msg
viewDestinationButtons =
    let
        classNames =
            "mr3 bg-beige-gray deep-blue pointer fw6 shadow-button"
    in
        div [ class "pt1 tc" ]
            [ epButton [ class classNames, onClick <| SetView ( Map.helsinkiLatLng, 12 ) ]
                [ text "Helsinki" ]
            , epButton [ class classNames, onClick <| SetView ( Map.worldLatLng, 1 ) ]
                [ text "World" ]
            , epButton [ class classNames, onClick <| GoToCurrentLocation ]
                [ text "Current" ]
            ]
