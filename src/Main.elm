module Main exposing (..)

import Html exposing (..)
import Html.Keyed
import Html.Lazy exposing (lazy, lazy2)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (..)
import Views exposing (epButton, avatar)
import Data.Entry exposing (Entry, EntryId, idToString)
import Dict exposing (Dict)
import Request.Entry exposing (decodePouchEntries, decodePouchEntry, decodeDeletedEntry)
import Page.Entry as Entry
import Page.Login as Login exposing (User)
import Map as Map
import Util exposing (viewDate, viewIf)
import Pouch.Ports


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = lazy view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Pouch.Ports.getEntries (decodePouchEntries NewEntries)
        , Pouch.Ports.updatedEntry (decodePouchEntry NewEntry)
        , Pouch.Ports.deletedEntry (decodeDeletedEntry DeletedEntry)

        -- Not a huge fan of this; I should be mapping the subs for Page.login
        , Pouch.Ports.logIn (Login.decodeLogin LoginCompleted)

        -- Should be in a Session module or so
        , Pouch.Ports.logOut (Login.decodeLogout LogOutCompleted)
        ]



-- MODEL


type Page
    = Blank
    | Entry Entry.Model
    | Login Login.Model


type alias Model =
    { entries : Dict String Entry
    , pageState : Page
    , mapState : Map.Model
    , loggedIn : Maybe User
    }


emptyModel : Model
emptyModel =
    { entries = Dict.empty
    , pageState = Entry Entry.initNew
    , mapState = Map.initModel
    , loggedIn = Nothing
    }


init : ( Model, Cmd Msg )
init =
    ( emptyModel
    , Cmd.batch
        [ Request.Entry.list
        , Pouch.Ports.checkAuthState "check"
        ]
    )



-- UPDATE


type Msg
    = NoOp
    | LoadEntries
    | ExportCardsOffline
    | ExportCardsOnline
    | SetPage Page
    | TogglePage
    | DeleteEntry EntryId
    | NewEntries (List Entry)
    | NewEntry (Result String Entry)
    | DeletedEntry (Result String EntryId)
    | LoginCompleted (Result String User)
    | LogOut
    | LogOutCompleted (Result String Bool)
    | EntryMsg Entry.Msg
    | LoginMsg Login.Msg
    | MapMsg Map.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Messages that exist for all "pages"
        NoOp ->
            model ! []

        SetPage pageState ->
            { model | pageState = pageState } ! []

        ExportCardsOffline ->
            model ! [ Pouch.Ports.exportCards "offline" ]

        ExportCardsOnline ->
            model ! [ Pouch.Ports.exportCards "online" ]

        TogglePage ->
            let
                nextPage =
                    case model.pageState of
                        Blank ->
                            Blank

                        Entry modelEntry ->
                            Login Login.initialModel

                        Login modelLogin ->
                            Entry Entry.initNew
            in
                update (SetPage nextPage) model

        DeleteEntry entryId ->
            model ! [ Request.Entry.delete entryId ]

        NewEntries entries ->
            let
                assocList =
                    List.map (\e -> ( idToString e.id, e )) entries

                newEntries =
                    Dict.fromList (assocList)
            in
                { model | entries = newEntries } ! [ Cmd.map MapMsg (Map.addMarkers entries) ]

        NewEntry (Err err) ->
            model ! []

        NewEntry (Ok entry) ->
            let
                newEntries =
                    Dict.insert (idToString entry.id) entry model.entries
            in
                { model | entries = newEntries } ! [ Cmd.map MapMsg (Map.addMarkers [ entry ]) ]

        DeletedEntry (Err err) ->
            model ! []

        DeletedEntry (Ok entryId) ->
            let
                newEntries =
                    Dict.remove (idToString entryId) model.entries

                ( newMapState, newMapCmd ) =
                    Map.update (Map.RemoveMarker entryId) model.mapState
            in
                ( { model
                    | entries = newEntries
                    , mapState = newMapState
                  }
                , Cmd.map MapMsg newMapCmd
                )

        LogOut ->
            ( model, Login.logout )

        LoginCompleted (Err err) ->
            model ! []

        LoginCompleted (Ok user) ->
            -- TODO: should be handled as messageToPage in updatePage below
            -- once subs are mapped
            { model | loggedIn = Just user } ! []

        LogOutCompleted (Err err) ->
            model ! []

        LogOutCompleted (Ok ok) ->
            { model | loggedIn = Nothing } ! []

        LoadEntries ->
            ( model, Pouch.Ports.listEntries "entry" )

        MapMsg msg ->
            -- more ad-hoc for Map messages, since we might want map to be co-located
            let
                ( newModel, newCmd ) =
                    Map.update msg model.mapState
            in
                ( { model | mapState = newModel }, Cmd.map MapMsg newCmd )

        -- Messages for another segment
        _ ->
            updatePage model.pageState msg model


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    -- More general function to abstract pages
    let
        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
                ( { model | pageState = (toModel newModel) }, Cmd.map toMsg newCmd )
    in
        case ( msg, page ) of
            ( EntryMsg subMsg, Entry subModel ) ->
                toPage Entry EntryMsg (Entry.update) subMsg subModel

            ( LoginMsg subMsg, Login subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        Login.update subMsg subModel

                    newModel =
                        case msgFromPage of
                            Login.NoOp ->
                                model

                            Login.SetUser user ->
                                { model | loggedIn = Just user }
                in
                    ( { newModel | pageState = (Login pageModel) }, Cmd.map LoginMsg cmd )

            ( _, Blank ) ->
                -- Disregard messages for Blank page/segment
                model ! []

            ( _, _ ) ->
                -- Disregard messages for wrong page/segment
                model ! []



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ viewHeader model.loggedIn
        , div [ class "pa3 pt0 ph5-ns bg-white" ]
            [ div [ class "mw7-ns center" ]
                [ div [ class "mb2 mb4-ns" ]
                    [ viewFlight
                    , lazy2 viewPage model model.pageState
                    , div [ class "measure center mt3" ]
                        [ epButton [ class "db mb3 w-100 white bg-deep-blue", onClick ExportCardsOffline ] [ text "Export CSV (offline)" ]
                        , epButton [ class "db w-100 white bg-deep-blue", onClick ExportCardsOnline ] [ text "Export Anki (online)" ]
                        ]
                    ]
                , div [ class "pt3" ]
                    [ lazy viewEntries (Dict.toList model.entries)
                    ]
                ]
            , viewFooter
            ]
        ]


viewHeader : Maybe User -> Html Msg
viewHeader loggedIn =
    let
        name =
            case loggedIn of
                Nothing ->
                    "Guest"

                Just user ->
                    user.username
    in
        div [ class "pa4" ]
            [ avatar name [ class "pointer mw4 center", onClick TogglePage ]
            ]


viewFooter : Html Msg
viewFooter =
    div [ class "mt4" ]
        [ hr [ class "mv0 w-100 bb bw1 b--black-10" ] []
        , div
            [ class "pv3 tc" ]
            [ p [ class "f6 lh-copy measure center" ]
                [ text "Ephemeral is an app for writing down words and their translations, as you encounter them"
                ]
            , span [ class "f6 lh-copy measure center" ]
                [ text "Made with 😭 by Fotis Papadogeogopoulos"
                ]
            ]
        ]


viewFlight : Html Msg
viewFlight =
    let
        classNames =
            "mr3 bg-beige-gray deep-blue pointer fw6 shadow-button"
    in
        div [ class "mb4 tc" ]
            [ epButton [ class classNames, onClick <| MapMsg (Map.SetLatLng ( Map.helsinkiLatLng, 12 )) ]
                [ text "Helsinki" ]
            , epButton [ class classNames, onClick <| MapMsg (Map.SetLatLng ( Map.worldLatLng, 1 )) ]
                [ text "World" ]
            , epButton [ class classNames, onClick <| MapMsg (Map.GoToCurrentLocation) ]
                [ text "Current" ]
            ]


viewPage : Model -> Page -> Html Msg
viewPage model page =
    -- Pass things to page's view
    case page of
        Blank ->
            Html.text ""

        Login subModel ->
            viewLoginLogout model.loggedIn subModel

        Entry subModel ->
            Entry.view subModel
                |> Html.map EntryMsg


viewLoginLogout : Maybe User -> Login.Model -> Html Msg
viewLoginLogout loggedIn subModel =
    case loggedIn of
        Just user ->
            div [ class "mt2 measure center" ]
                [ p [ class "lh-copy f5 mb3 black-80" ] [ text "Note that logging out does not delete your local files. If you log in again, then the database will attempt to synchronise with the remote. This may or may not be what you intend." ]
                , epButton [ class "w-100 white bg-deep-blue", onClick LogOut ] [ text "Log Out" ]
                ]

        Nothing ->
            Login.view subModel
                |> Html.map LoginMsg


viewEntries : List ( String, Entry ) -> Html Msg
viewEntries keyedEntries =
    if keyedEntries /= [] then
        Html.Keyed.node "div" [ class "dw" ] <| List.map (\( id, entry ) -> ( id, lazy viewEntry entry )) keyedEntries
    else
        div [ class "pa4 mb3 bg-main-blue br1 tc f5" ]
            [ p [ class "dark-gray lh-copy" ]
                [ text "Looks like you don't have any entries yet. Why don't you add one? :)"
                ]
            ]


viewEntry : Entry -> Html Msg
viewEntry entry =
    div
        [ class "dw-panel" ]
        [ div
            [ class "dw-panel__content bg-muted-blue mw5 center br4 pa4 shadow-card" ]
            [ a [ onClick <| DeleteEntry entry.id, class "close handwriting black-70 hover-white" ] [ text "×" ]
            , div [ class "white tl" ]
                [ h2
                    [ class "mt0 mb2 f5 f4-ns fw6 overflow-hidden" ]
                    [ text entry.content ]
                , h2
                    [ class "mt0 f5 f4-ns fw6 overflow-hidden" ]
                    [ text entry.translation ]
                ]
            , hr
                [ class "w-100 mt4 mb3 bb bw1 b--black-10" ]
                []
            , div [ class "white f6 f5-ns" ]
                [ span [ class "db mb2 tr truncate" ] [ text <| viewDate entry.addedAt ]
                , span [ class "db mb1 tr truncate" ] [ text <| toString entry.location.latitude ++ ", " ]
                , span [ class "db tr truncate" ] [ text <| toString entry.location.longitude ]
                ]
            ]
        ]



-- viewEntryFlip : Entry -> Html Msg
-- viewEntryFlip entry =
--     div
--         [ class "dw-panel dw-flip dw-flip--md" ]
--         [ div
--             [ class "dw-panel__content dw-flip__content white" ]
--             [ div
--                 [ class "dw-flip__panel dw-flip__panel--front bg-muted-blue mw5 center br4 pa4 shadow-card" ]
--                 [ h2
--                     [ class "mt0 mb2 f5 f4-ns fw6 overflow-hidden" ]
--                     [ text entry.content ]
--                 , hr
--                     [ class "w-100 mt4 mb3 bb bw1 b--black-10" ]
--                     []
--                 , div [ class "near-white f6 f5-ns" ]
--                     [ span [ class "db mb2 tr truncate" ] [ text <| viewDate entry.addedAt ]
--                     , span [ class "db mb1 tr truncate" ] [ text <| toString entry.location.latitude ++ ", " ]
--                     , span [ class "db tr truncate" ] [ text <| toString entry.location.longitude ]
--                     ]
--                 ]
--             , div
--                 [ class "dw-flip__panel dw-flip__panel--back bg-light-blue mw5 center br4 pa4 shadow-card" ]
--                 [ h2
--                     [ class "mt0 f5 f4-ns fw6 overflow-hidden" ]
--                     [ text entry.translation ]
--                 ]
--             ]
--         ]
