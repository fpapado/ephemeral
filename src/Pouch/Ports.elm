port module Pouch.Ports exposing (saveEntry, listEntries, getEntries)

import Json.Encode exposing (Value)


port listEntries : String -> Cmd msg


port saveEntry : Json.Encode.Value -> Cmd msg


port getEntries : (Value -> msg) -> Sub msg
