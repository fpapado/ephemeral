module Data.Entry exposing (..)

import Date exposing (Date)
import Json.Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra
import Json.Decode.Pipeline as Pipeline exposing (decode, required)


type alias Entry =
    { content : String
    , translation : String
    , addedAt : Date
    , location : EntryLocation
    , id : EntryId
    }


type alias EntryLocation =
    { latitude : Float
    , longitude : Float
    , accuracy : Int
    }



-- SERIALISATION --


decodeEntry : Decoder Entry
decodeEntry =
    decode Entry
        |> required "content" (Decode.string)
        |> required "translation" (Decode.string)
        |> required "added_at" (Json.Decode.Extra.date)
        |> required "location" (decodeEntryLocation)
        |> required "id" entryIdDecoder


decodeEntryLocation : Decoder EntryLocation
decodeEntryLocation =
    decode EntryLocation
        |> required "latitude" (Json.Decode.Extra.parseFloat)
        |> required "longitude" (Json.Decode.Extra.parseFloat)
        |> required "accuracy" (Decode.int)


encodeEntry : Entry -> Json.Encode.Value
encodeEntry record =
    Json.Encode.object
        [ ( "content", Json.Encode.string <| record.content )
        , ( "translation", Json.Encode.string <| record.translation )
        , ( "added_at", Json.Encode.string <| toString record.addedAt )
        , ( "location", encodeEntryLocation <| record.location )
        ]


encodeEntryLocation : EntryLocation -> Json.Encode.Value
encodeEntryLocation record =
    Json.Encode.object
        [ ( "latitude", Json.Encode.float <| record.latitude )
        , ( "longitude", Json.Encode.float <| record.longitude )
        , ( "accuracy", Json.Encode.int <| record.accuracy )
        ]



-- IDENTIFIERS --


type EntryId
    = EntryId Int


idToString : EntryId -> String
idToString (EntryId id) =
    toString id


entryIdDecoder : Decoder EntryId
entryIdDecoder =
    Decode.map EntryId Decode.int
