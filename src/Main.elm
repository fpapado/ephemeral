module Main exposing (..)

import Task
import Html exposing (..)
import Data.Session exposing (Session)
import Data.User exposing (User)
import Request.Entry exposing (decodePouchEntries, decodePouchEntry, decodeDeletedEntry)
import Route exposing (Route)
import Views.Page as Page exposing (ActivePage)
import Page.Entry as Entry
import Page.Home as Home
import Page.Login as Login
import Page.NotFound as NotFound
import Page.Errored as Errored exposing (PageLoadError)
import Util exposing ((=>))
import Pouch.Ports
import Navigation exposing (Location)


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
    -- TODO: add login/logout sub here
    Sub.batch
        [ pageSubscriptions (getPage model.pageState) ]


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

        Login _ ->
            Sub.none



-- MSG --


type Msg
    = SetRoute (Maybe Route)
    | HomeLoaded (Result PageLoadError Home.Model)
    | HomeMsg Home.Msg
    | EntryMsg Entry.Msg
    | LoginMsg Login.Msg



-- TODO: move to Login


type LogMSg
    = LoginCompleted (Result String User)
    | LogOut
    | LogOutCompleted (Result String Bool)



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
                -- TODO: could send LoadEntries cmd here?
                { model | pageState = Loaded (Home Home.init) } => Cmd.none

            Just Route.Login ->
                { model | pageState = Loaded (Login Login.initialModel) } => Cmd.none

            Just Route.Logout ->
                let
                    session =
                        model.session
                in
                    { model | session = { session | user = Nothing } }
                        => Cmd.batch
                            -- [ Ports.rtoreSession Nothing
                            [ Route.modifyUrl Route.Home
                            ]

            Just Route.NewEntry ->
                { model | pageState = Loaded (Entry Entry.init) } => Cmd.none

            Just Route.Settings ->
                errored Page.Other "Settings WIP"



-- case model.session.user of
-- Just user ->
-- { model | pageState = Loaded (Settings (Settings.init user)) } => Cmd.none
-- Nothing ->
-- errored Page.Settings "You must be signed in to access your settings."


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



-- Messages that exist for all "pages"
-- case msg of
-- LogOut ->
-- -- ( model, Login.logout )
-- model ! []
-- LoginCompleted (Err err) ->
-- model => Cmd.none
-- LoginCompleted (Ok user) ->
-- -- TODO: should be handled as messageToPage in updatePage below
-- -- once subs are mapped
-- let
-- session =
-- model.session
-- newSession =
-- { session | user = Just user }
-- in
-- { model | session = newSession } => Cmd.none
-- LogOutCompleted (Err err) ->
-- model ! []
-- LogOutCompleted (Ok ok) ->
-- let
-- session =
-- model.session
-- newSession =
-- { session | user = Nothing }
-- in
-- { model | session = newSession } ! []
-- Messages for another page


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
        -- = SetRoute (Maybe Route)
        -- | HomeLoaded (Result PageLoadError Home.Model)
        -- | HomeMsg Home.Msg
        -- | EntryMsg Entry.Msg
        -- | LoginMsg Login.Msg
        case ( msg, page ) of
            ( SetRoute route, _ ) ->
                setRoute route model

            ( HomeLoaded (Ok subModel), _ ) ->
                { model | pageState = Loaded (Home subModel) } => Cmd.none

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
