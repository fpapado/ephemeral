module Views exposing (formField, epButton, avatar)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


formField : String -> (String -> msg) -> String -> String -> String -> String -> Html msg
formField inputValue msg inputId labelText inputType descText =
    -- TODO: That signature, consider a config record of some kind
    -- TODO: allow extra attributes
    div [ class "mb3" ]
        [ label [ class "f6 b db mv2", for inputId ] [ text labelText ]
        , input
            [ attribute "aria-describedby" <| inputId ++ "-desc"
            , value inputValue
            , class "input-reset ba b--black-20 pa2 mb2 db w-100 br1"
            , id inputId
            , type_ inputType
            , onInput msg
            ]
            []
        , small [ class "f6 black-60 db mb2", id <| inputId ++ "-desc" ]
            [ text descText ]
        ]


epButton : List (Attribute msg) -> List (Html msg) -> Html msg
epButton attributes children =
    button
        ((class "f6 link dim pa3 dib bg-dark-blue bw0 br1 pointer")
            :: attributes
        )
        children


avatar : String -> List (Attribute msg) -> Html msg
avatar name attributes =
    div
        ((class "flex items-center justify-center") :: attributes)
        [ img
            [ src "icon.png", class "br-100 h2 w2 mr2 bg-main-blue", alt "avatar" ]
            []
        , span [ class "db fw6 f6 black-80" ] [ text name ]
        ]
