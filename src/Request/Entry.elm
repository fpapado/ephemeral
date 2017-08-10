module Request.Entry exposing (list, create, update, createPouch, listPouch, decodeEntryList)

import Data.Entry as Entry exposing (Entry, EntryId, EntryLocation, encodeEntry, encodeEntryLocation, idToString)
import Date exposing (Date)
import Date.Extra.Format exposing (utcIsoString)
import Http
import HttpBuilder exposing (RequestBuilder, withExpect, withQueryParams, withBody)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Request.Helpers exposing (apiUrl)
import Pouch.Ports


-- LIST --


list : Http.Request (List Entry)
list =
    apiUrl ("/notes/")
        |> HttpBuilder.get
        |> HttpBuilder.withExpect (Http.expectJson decodeEntryList)
        |> HttpBuilder.toRequest



-- CREATE --


type alias CreateConfig record =
    { record
        | content : String
        , translation : String
        , addedAt : Date
        , location : EntryLocation
    }


type alias EditConfig record =
    { record
        | content : String
        , translation : String
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


update : EntryId -> EditConfig record -> Http.Request Entry
update entryId config =
    let
        expect =
            Entry.decodeEntry
                |> Http.expectJson

        entry =
            Encode.object
                [ ( "content", Encode.string config.content )
                , ( "translation", Encode.string config.translation )
                ]

        body =
            entry |> Http.jsonBody
    in
        apiUrl ("/notes/" ++ idToString entryId)
            |> HttpBuilder.patch
            |> withBody body
            |> withExpect expect
            |> HttpBuilder.toRequest



-- CREATE POUCH --


createPouch : CreateConfig record -> Cmd msg
createPouch config =
    let
        entry =
            Encode.object
                [ ( "content", Encode.string config.content )
                , ( "translation", Encode.string config.translation )
                , ( "added_at", Encode.string <| utcIsoString config.addedAt )
                , ( "location", encodeEntryLocation config.location )
                ]
    in
        Pouch.Ports.saveEntry entry


listPouch : Cmd msg
listPouch =
    Pouch.Ports.listEntries "list"


decodeEntryList : Decode.Decoder (List Entry)
decodeEntryList =
    Decode.list (Entry.decodeEntry)
