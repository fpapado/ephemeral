module Views.Page exposing (ActivePage(..), frame, fullFrame)

import Data.User exposing (User)
import Html exposing (..)
import Html.Attributes exposing (..)
import Route exposing (Route)
import Views.General exposing (avatar, epButton)
import Views.Icons as Icons


type ActivePage
    = Other
    | Home
    | Login
    | Settings
    | NewEntry
    | FullMap


frame : Maybe User -> ActivePage -> Html msg -> Html msg
frame user page content =
    div []
        [ viewMenu page user

        -- , viewHeader user
        , div [ class "pa3 pt4 ph5-ns bg-white" ]
            [ div [ class "mw7-ns center" ] [ content ]
            , viewFooter
            ]
        ]


fullFrame : Maybe User -> ActivePage -> Html msg -> Html msg
fullFrame user page content =
    div []
        [ viewMenu page user
        ]


viewMenu : ActivePage -> Maybe User -> Html msg
viewMenu page user =
    div [ class "h-nav fixed bottom-0 left-0 w-100 z-999" ]
        [ nav [ class "h-100 mw7-ns center flex flex-row f6 f5-ns black bg-nav bt b--black-20" ] <|
            [ navbarLink (page == Home) Route.Home [ iconAndText Icons.list "List" ]
            , navbarLink (page == NewEntry) Route.NewEntry [ iconAndText Icons.edit "Add" ]
            , navbarLink (page == FullMap) Route.FullMap [ iconAndText Icons.map "Add" ]
            , navbarLink (page == Settings) Route.Settings [ iconAndText Icons.settings "Settings" ]
            ]
                ++ viewSignIn page user
        ]


viewSignIn : ActivePage -> Maybe User -> List (Html msg)
viewSignIn page user =
    case user of
        Nothing ->
            [ navbarLink (page == Login) Route.Login [ iconAndText Icons.logIn "Login" ]
            ]

        Just user ->
            [ navbarLink False Route.Logout [ iconAndText Icons.logOut "Logout" ]
            ]


iconAndText : Html msg -> a -> Html msg
iconAndText icon txt =
    -- , p [ class "mt1 mb0" ] [ text txt ]
    div [ class "mv0 center relative flex flex-column items-center justify-center" ] [ icon ]


viewHeader : Maybe User -> Html msg
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
            [ avatar name [ class "pointer mw4 center" ]
            ]


viewFooter : Html msg
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


navbarLink : Bool -> Route -> List (Html msg) -> Html msg
navbarLink isActive route linkContent =
    div [ class "h-100 flex flex-column flex-grow-1 justify-center items-center" ]
        [ a [ classList [ ( "w-100 h-100 flex items-center b", True ), ( "white hover-white", isActive ), ( "dim nav-disabled", not isActive ) ], Route.href route ] linkContent ]
