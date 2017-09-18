module Views.Page exposing (ActivePage(..), frame)

import Html exposing (..)
import Html.Attributes exposing (..)
import Data.User exposing (User)
import Views.General exposing (epButton, avatar)
import Route exposing (Route)


type ActivePage
    = Other
    | Home
    | Login
    | Settings
    | NewEntry


frame : Maybe User -> ActivePage -> Html msg -> Html msg
frame user page content =
    div []
        [ viewMenu page user
        , viewHeader user
        , div [ class "pa3 pt0 ph5-ns bg-white" ]
            [ div [ class "mw7-ns center" ] [ content ]
            , viewFooter
            ]
        ]


viewMenu : ActivePage -> Maybe User -> Html msg
viewMenu page user =
    div [ class "fixed bottom-0 left-0 w-100 z-1" ]
        [ nav [ class "pv2 mw7-ns center flex flex-row justify-center items-center space-around black-80 bg-beige-gray-2" ] <|
            [ navbarLink (page == Home) Route.Home [ text "Home" ]
            , navbarLink (page == NewEntry) Route.NewEntry [ text "Add" ]
            , navbarLink (page == Settings) Route.Settings [ text "Settings" ]
            ]
                ++ viewSignIn page user
        ]


viewSignIn : ActivePage -> Maybe User -> List (Html msg)
viewSignIn page user =
    case user of
        Nothing ->
            [ navbarLink (page == Login) Route.Login [ text "Log in" ]
            ]

        Just user ->
            [ navbarLink False Route.Logout [ text "Sign out" ]
            ]


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
    div [ classList [ ( "pa3", True ) ] ]
        [ a [ classList [ ( "dim link f6 b", True ), ( "deep-blue", isActive ), ( "black-80", not isActive ) ], Route.href route ] linkContent ]
