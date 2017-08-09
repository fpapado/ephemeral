module Util exposing (viewDate)

import Date exposing (Date)
import Date.Extra.Config.Config_en_gb exposing (config)
import Date.Extra.Format exposing (format)


viewDate : Date -> String
viewDate date =
    format config config.format.dateTime date
