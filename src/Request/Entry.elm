module Request.Entry exposing (list)

import Data.Entry as Entry exposing (Entry, EntryId)
import Http
import HttpBuilder exposing (RequestBuilder, withExpect, withQueryParams)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Request.Helpers exposing (apiUrl)


-- LIST --


list : Http.Request (List Entry)
list =
    apiUrl ("/notes/")
        |> HttpBuilder.get
        |> HttpBuilder.withExpect (Http.expectJson (Decode.field "notes" (Decode.list Entry.decodeEntry)))
        |> HttpBuilder.toRequest
