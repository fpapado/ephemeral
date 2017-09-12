module Views.Page exposing (ActivePage(..), frame)

import Html exposing (..)
import Html.Keyed
import Html.Lazy exposing (lazy, lazy2)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (..)
import Data.User exposing (User)
import Page.Login as Login
import Views.General exposing (epButton, avatar)


-- TODO: use for viewMenu


type ActivePage
    = Other
    | Home
    | Login
    | Settings
    | NewEntry


frame : Maybe User -> ActivePage -> Html msg -> Html msg
frame user page content =
    div []
        [ viewHeader user

        -- , viewMenu page # TODO: manages which link is active
        , div [ class "pa3 pt0 ph5-ns bg-white" ]
            [ div [ class "mw7-ns center" ] [ content ]
            , viewFooter
            ]
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
