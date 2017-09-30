module Util exposing ((=>), pair, viewDate, viewIf)

import Html exposing (Html)
import Date exposing (Date)
import Date.Extra.Config.Config_en_gb exposing (config)
import Date.Extra.Format exposing (format)


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


{-| infixl 0 means the (=>) operator has the same precedence as (<|) and (|>),
meaning you can use it at the end of a pipeline and have the precedence work out.
-}
infixl 0 =>


{-| Useful when building up a Cmd via a pipeline, and then pairing it with
a model at the end.
session.user
|> User.Request.foo
|> Task.attempt Foo
|> pair { model | something = blah }
-}
pair : a -> b -> ( a, b )
pair first second =
    first => second


viewDate : Date -> String
viewDate date =
    format config config.format.dateTime date


viewIf : Bool -> Html msg -> Html msg
viewIf condition content =
    if condition then
        content
    else
        Html.text ""
