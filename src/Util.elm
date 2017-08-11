module Util exposing (viewDate, viewIf)

import Html exposing (Html)
import Date exposing (Date)
import Date.Extra.Config.Config_en_gb exposing (config)
import Date.Extra.Format exposing (format)


viewDate : Date -> String
viewDate date =
    format config config.format.dateTime date


viewIf : Bool -> Html msg -> Html msg
viewIf condition content =
    if condition then
        content
    else
        Html.text ""
