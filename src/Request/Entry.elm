module Request.Entry exposing (list, create)

import Data.Entry as Entry exposing (Entry, EntryId, EntryLocation, encodeEntry, encodeEntryLocation)
import Date exposing (Date)
import Date.Extra.Format exposing (utcIsoString)
import Http
import HttpBuilder exposing (RequestBuilder, withExpect, withQueryParams, withBody)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Request.Helpers exposing (apiUrl)


-- LIST --


list : Http.Request (List Entry)
list =
    apiUrl ("/notes/")
        |> HttpBuilder.get
        |> HttpBuilder.withExpect (Http.expectJson (Decode.list Entry.decodeEntry))
        |> HttpBuilder.toRequest



-- CREATE --


type alias CreateConfig record =
    { record
        | content : String
        , translation : String
        , addedAt : Date
        , location : EntryLocation
    }


create : CreateConfig record -> Http.Request Entry
create config =
    let
        expect =
            Entry.decodeEntry
                |> Http.expectJson

        entry =
            Encode.object
                [ ( "content", Encode.string config.content )
                , ( "translation", Encode.string config.translation )
                , ( "added_at", Encode.string <| utcIsoString config.addedAt )
                , ( "location", encodeEntryLocation config.location )
                ]

        body =
            entry
                |> Http.jsonBody
    in
        apiUrl "/notes"
            |> HttpBuilder.post
            |> withBody body
            |> withExpect expect
            |> HttpBuilder.toRequest



-- type alias EditConfig record =
--     { record
--         | content : String
--         , translation : String
--         , addedAt : Date
--         , location : EntryLocation
--     }
