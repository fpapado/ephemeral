module Leaflet.Types
    exposing
        ( LatLng
        , ZoomPanOptions
        , defaultZoomPanOptions
        , MarkerOptions
        , defaultMarkerOptions
        , encodeMarkerOptions
        , encodeIconOptions
        , encodePoint
        , encodeLatLng
        , encodeZoomPanOptions
        )

import Json.Encode as E


type alias LatLng =
    ( Float, Float )


encodeLatLng : LatLng -> E.Value
encodeLatLng ( lat, lng ) =
    E.list
        [ E.float lat
        , E.float lng
        ]


{-| Reference: <http://leafletjs.com/reference.html#marker-options>
-}
type alias MarkerOptions =
    { icon : IconOptions
    , clickable : Bool
    , draggable : Bool
    , keyboard : Bool
    , title : String
    , alt : String
    , zIndexOffset : Int
    , opacity : Float
    , riseOnHover : Bool
    , riseOffset : Int
    }


encodeMarkerOptions : MarkerOptions -> E.Value
encodeMarkerOptions opts =
    E.object
        [ ( "icon", encodeIconOptions opts.icon )
        , ( "clickable", E.bool opts.clickable )
        , ( "draggable", E.bool opts.draggable )
        , ( "keyboard", E.bool opts.keyboard )
        , ( "title", E.string opts.title )
        , ( "alt", E.string opts.alt )
        , ( "zIndexOffset", E.int opts.zIndexOffset )
        , ( "opacity", E.float opts.opacity )
        , ( "riseOnHover", E.bool opts.riseOnHover )
        , ( "riseOffset", E.int opts.riseOffset )
        ]


defaultMarkerOptions : MarkerOptions
defaultMarkerOptions =
    { icon = defaultIconOptions
    , clickable = True
    , draggable = False
    , keyboard = True
    , title = ""
    , alt = ""
    , zIndexOffset = 0
    , opacity = 1.0
    , riseOnHover = False
    , riseOffset = 250
    }


{-| Reference: <http://leafletjs.com/reference.html#icon-options>
-}
type alias IconOptions =
    { iconUrl : String
    , iconRetinaUrl : String
    , iconSize : Point
    , iconAnchor : Point
    , shadowUrl : String
    , shadowRetinaUrl : String
    , shadowSize : Point
    , shadowAnchor : Point
    , popupAnchor : Point
    , className : String
    }


encodeIconOptions : IconOptions -> E.Value
encodeIconOptions opts =
    E.object
        [ ( "iconUrl", E.string opts.iconUrl )
        , ( "iconRetinaUrl", E.string opts.iconRetinaUrl )
        , ( "iconSize", encodePoint opts.iconSize )
        , ( "iconAnchor", encodePoint opts.iconAnchor )
        , ( "shadowUrl", E.string opts.shadowUrl )
        , ( "shadowRetinaUrl", E.string opts.shadowRetinaUrl )
        , ( "shadowSize", encodePoint opts.shadowSize )
        , ( "shadowAnchor", encodePoint opts.shadowAnchor )
        , ( "popupAnchor", encodePoint opts.popupAnchor )
        , ( "className", E.string opts.className )
        ]


leafletDistributionBase : String
leafletDistributionBase =
    "https://unpkg.com/leaflet@1.2.0/dist/images/"


iconUrl : String -> String
iconUrl filename =
    leafletDistributionBase ++ filename


defaultIconOptions : IconOptions
defaultIconOptions =
    { iconUrl = iconUrl "marker-icon.png"
    , iconRetinaUrl = iconUrl "marker-icon-2x.png"
    , iconSize = ( 25, 41 )
    , iconAnchor = ( 12, 41 )
    , shadowUrl = iconUrl "marker-shadow.png"
    , shadowRetinaUrl =
        iconUrl "marker-shadow.png"

    -- Really just guessing here, doesn't appear to be set by default?
    , shadowSize = ( 41, 41 )
    , shadowAnchor = ( 12, 41 )
    , popupAnchor = ( 1, -34 )
    , className = ""
    }


type alias Point =
    ( Int, Int )


encodePoint : Point -> E.Value
encodePoint ( x, y ) =
    E.list
        [ E.int x
        , E.int y
        ]


type alias ZoomOptions =
    { animate : Bool }


encodeZoomOptions : ZoomOptions -> E.Value
encodeZoomOptions opts =
    E.object
        [ ( "animate", E.bool opts.animate )
        ]


type alias PanOptions =
    { animate : Bool
    , duration : Float
    , easeLinearity : Float
    , noMoveStart : Bool
    }


encodePanOptions : PanOptions -> E.Value
encodePanOptions opts =
    E.object
        [ ( "animate", E.bool opts.animate )
        , ( "duration", E.float opts.duration )
        , ( "easeLinearity", E.float opts.easeLinearity )
        , ( "noMoveStart", E.bool opts.noMoveStart )
        ]


type alias ZoomPanOptions =
    { reset : Bool
    , pan : PanOptions
    , zoom : ZoomOptions
    , animate : Bool
    }


encodeZoomPanOptions : ZoomPanOptions -> E.Value
encodeZoomPanOptions opts =
    E.object
        [ ( "reset", E.bool opts.reset )
        , ( "pan", encodePanOptions opts.pan )
        , ( "zoom", encodeZoomOptions opts.zoom )
        , ( "animate", E.bool opts.animate )
        ]


defaultZoomPanOptions : ZoomPanOptions
defaultZoomPanOptions =
    { reset = False
    , pan = defaultPanOptions
    , zoom = defaultZoomOptions
    , animate = True
    }


defaultPanOptions : PanOptions
defaultPanOptions =
    { animate = True
    , duration = 0.25
    , easeLinearity = 0.25
    , noMoveStart = False
    }


defaultZoomOptions : ZoomOptions
defaultZoomOptions =
    { animate = True }
