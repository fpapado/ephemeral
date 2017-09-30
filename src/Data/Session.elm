module Data.Session exposing (Session)

import Data.User as User exposing (User)


type alias Session =
    { user : Maybe User }
