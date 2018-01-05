module Page.FullMap exposing (view)

import Data.Session as Session exposing (Session)
import Html exposing (Html, main_)


-- VIEW --


view : Session -> Html msg
view session =
    main_ [] []
