port module Pouch.Ports
    exposing
        ( saveEntry
        , updateEntry
        , deleteEntry
        , listEntries
        , sendLogin
        , sendLogout
        , exportCards
        , getEntries
        , newEntry
        , updatedEntry
        , deletedEntry
        , logIn
        , logOut
        , checkAuthState
        )

import Json.Encode exposing (Value)


port listEntries : String -> Cmd msg


port exportCards : String -> Cmd msg


port saveEntry : Json.Encode.Value -> Cmd msg


port updateEntry : Json.Encode.Value -> Cmd msg


port deleteEntry : String -> Cmd msg


port sendLogin : Json.Encode.Value -> Cmd msg


port sendLogout : String -> Cmd msg


port checkAuthState : String -> Cmd msg


port getEntries : (Value -> msg) -> Sub msg


port newEntry : (Value -> msg) -> Sub msg


port updatedEntry : (Value -> msg) -> Sub msg


port deletedEntry : (Value -> msg) -> Sub msg


port logIn : (Value -> msg) -> Sub msg


port logOut : (Value -> msg) -> Sub msg
