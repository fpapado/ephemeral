module Views.Page exposing (ActivePage(..), frame)

import Html exposing (..)
import Html.Lazy exposing (lazy, lazy2)
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
    nav [ class "pv3 flex flex-row justify-center items-center space-around black-80" ]
        [ navbarLink (page == Home) Route.Home [ text "Home" ]
        , navbarLink (page == NewEntry) Route.NewEntry [ text "Add" ]
        , navbarLink (page == Settings) Route.Settings [ text "Settings" ]
        , navbarLink (page == Login) Route.Login [ text "Log In" ]
        ]


navbarLink : Bool -> Route -> List (Html msg) -> Html msg
navbarLink isActive route linkContent =
    div [ classList [ ( "pa3", True ) ] ]
        [ a [ classList [ ( "dim link", True ), ( "deep-blue", isActive ), ( "black-80", not isActive ) ], Route.href route ] linkContent ]



-- viewSignIn : ActivePage -> Maybe User -> List (Html msg)
-- viewSignIn page user =
-- case user of
-- Nothing ->
-- [ navbarLink (page == Login) Route.Login [ text "Sign in" ]
-- , navbarLink (page == Register) Route.Register [ text "Sign up" ]
-- ]
-- Just user ->
-- [ navbarLink (page == NewArticle) Route.NewArticle [ i [ class "ion-compose" ] [], text " New Post" ]
-- , navbarLink (page == Settings) Route.Settings [ i [ class "ion-gear-a" ] [], text " Settings" ]
-- , navbarLink
-- (page == Profile user.username)
-- (Route.Profile user.username)
-- [ img [ class "user-pic", UserPhoto.src user.image ] []
-- , User.usernameToHtml user.username
-- ]
-- , navbarLink False Route.Logout [ text "Sign out" ]
-- ]


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



-- TODO: Add to Page.Login
-- viewLoginLogout : Maybe User -> Login.Model -> Html Msg
-- viewLoginLogout loggedIn subModel =
-- case loggedIn of
-- Just user ->
-- div [ class "mt2 measure center" ]
-- [ p [ class "lh-copy f5 mb3 black-80" ] [ text "Note that logging out does not delete your local files. If you log in again, then the database will attempt to synchronise with the remote. This may or may not be what you intend." ]
-- , epButton [ class "w-100 white bg-deep-blue", onClick LogOut ] [ text "Log Out" ]
-- ]
-- Nothing ->
-- Login.view subModel
-- |> Html.map LoginMsg
