module Main exposing (..)

import Task
import Html exposing (..)
import Data.Session exposing (Session)
import Request.Entry exposing (decodePouchEntries, decodePouchEntry, decodeDeletedEntry)
import Route exposing (Route)
import Views.Page as Page exposing (ActivePage)
import Page.Entry as Entry
import Page.Home as Home
import Page.Login as Login exposing (logout)
import Page.NotFound as NotFound
import Page.Errored as Errored exposing (PageLoadError)
import Util exposing ((=>))
import Navigation exposing (Location)
import Pouch.Ports


type Page
    = Blank
    | NotFound
    | Errored PageLoadError
    | Home Home.Model
    | Entry Entry.Model
    | Login Login.Model



-- | Settings User
-- MODEL --


type alias Model =
    { session : Session
    , pageState : PageState
    }


type PageState
    = Loaded Page
    | TransitioningFrom Page


init : Location -> ( Model, Cmd Msg )
init location =
    setRoute (Route.fromLocation location) initModel


initModel : Model
initModel =
    -- TODO: check
    { session = { user = Nothing }
    , pageState = Loaded initialPage
    }


initialPage : Page
initialPage =
    Blank



-- VIEW


view : Model -> Html Msg
view model =
    case model.pageState of
        Loaded page ->
            viewPage model.session False page

        TransitioningFrom page ->
            viewPage model.session True page


viewPage : Session -> Bool -> Page -> Html Msg
viewPage session isLoading page =
    let
        frame =
            Page.frame session.user
    in
        case page of
            Blank ->
                Html.text ""
                    |> frame Page.Other

            NotFound ->
                NotFound.view session
                    |> frame Page.Other

            Errored subModel ->
                Errored.view session subModel
                    |> frame Page.Other

            Home subModel ->
                Home.view subModel
                    |> frame Page.Home
                    |> Html.map HomeMsg

            Entry subModel ->
                Entry.view subModel
                    |> frame Page.NewEntry
                    |> Html.map EntryMsg

            -- Settings subModel ->
            -- Errored.view session subModel
            -- |> frame Page.Other
            -- TODO: Add once Page.Settings implemented
            -- Entry.view subModel
            -- |> frame Page.Settings
            -- |> Html.map SettingsMsg
            Login subModel ->
                Login.view subModel
                    |> frame Page.Login
                    |> Html.map LoginMsg


getPage : PageState -> Page
getPage pageState =
    case pageState of
        Loaded page ->
            page

        TransitioningFrom page ->
            page



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    -- Combine page-specific subs plus global ones (namely, session)
    Sub.batch
        [ pageSubscriptions (getPage model.pageState)
        , Pouch.Ports.logOut (Login.decodeLogout LogOutCompleted)
        ]


pageSubscriptions : Page -> Sub Msg
pageSubscriptions page =
    case page of
        Blank ->
            Sub.none

        Errored _ ->
            Sub.none

        NotFound ->
            Sub.none

        Home subModel ->
            Sub.map (\msg -> HomeMsg msg) (Home.subscriptions subModel)

        -- Settings _ ->
        -- Sub.none
        Entry _ ->
            Sub.none

        Login subModel ->
            Sub.map (\msg -> LoginMsg msg) (Login.subscriptions subModel)



-- MSG --


type Msg
    = SetRoute (Maybe Route)
    | HomeLoaded (Result PageLoadError Home.Model)
    | LogOutCompleted (Result String Bool)
    | HomeMsg Home.Msg
    | EntryMsg Entry.Msg
    | LoginMsg Login.Msg



-- ROUTE MAPS --


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    let
        transition toMsg task =
            { model | pageState = TransitioningFrom (getPage model.pageState) }
                => Task.attempt toMsg task

        errored =
            pageErrored model
    in
        case maybeRoute of
            Nothing ->
                { model | pageState = Loaded NotFound } => Cmd.none

            Just Route.Home ->
                -- transition HomeLoaded (Home.init model.session)
                { model | pageState = Loaded (Home Home.init) } => Request.Entry.list

            Just Route.Login ->
                { model | pageState = Loaded (Login Login.initialModel) } => Cmd.none

            Just Route.Logout ->
                -- Login.logout gets back on a port in subscriptions
                -- Handling of it (deleting user, routing home) is handled in
                -- Main.update
                model
                    => Cmd.batch [ Login.logout ]

            Just Route.NewEntry ->
                { model | pageState = Loaded (Entry Entry.init) } => Cmd.none

            Just Route.Settings ->
                errored Page.Other "Settings WIP"


pageErrored : Model -> ActivePage -> String -> ( Model, Cmd msg )
pageErrored model activePage errorMessage =
    let
        error =
            Errored.pageLoadError activePage errorMessage
    in
        { model | pageState = Loaded (Errored error) } => Cmd.none



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    updatePage (getPage model.pageState) msg model


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    let
        session =
            model.session

        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
                ( { model | pageState = Loaded (toModel newModel) }, Cmd.map toMsg newCmd )

        errored =
            pageErrored model
    in
        case ( msg, page ) of
            ( SetRoute route, _ ) ->
                setRoute route model

            ( LogOutCompleted (Ok user), _ ) ->
                let
                    session =
                        model.session
                in
                    { model | session = { session | user = Nothing } }
                        => Cmd.batch [ Route.modifyUrl Route.Home ]

            ( LogOutCompleted (Err error), _ ) ->
                model => Cmd.none

            ( HomeLoaded (Ok subModel), _ ) ->
                { model | pageState = Loaded (Home subModel) } => Request.Entry.list

            ( HomeLoaded (Err error), _ ) ->
                { model | pageState = Loaded (Errored error) } => Cmd.none

            ( HomeMsg subMsg, Home subModel ) ->
                toPage Home HomeMsg (Home.update session) subMsg subModel

            ( EntryMsg subMsg, Entry subModel ) ->
                toPage Entry EntryMsg (Entry.update session) subMsg subModel

            ( LoginMsg subMsg, Login subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        Login.update subMsg subModel

                    newModel =
                        case msgFromPage of
                            Login.NoOp ->
                                model

                            Login.SetUser user ->
                                let
                                    session =
                                        model.session

                                    newSession =
                                        { session | user = Just user }
                                in
                                    { model | session = newSession }
                in
                    { newModel | pageState = Loaded (Login pageModel) }
                        => Cmd.map LoginMsg cmd

            ( _, NotFound ) ->
                -- Disregard messages when on NotFound page
                model => Cmd.none

            ( _, _ ) ->
                -- Disregard messages for wrong page
                model => Cmd.none


main : Program Never Model Msg
main =
    Navigation.program (Route.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
