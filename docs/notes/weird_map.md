I ran into an issue with the map, where locally on dev mode, starting directly
at /map (the fullscreen map page), Leaflet fails to initalise the correct size.
In fact, this also happens in Home, but ameliorated by the slower SetMarkers
which comes after and also calls invalidateSize(). This looks like a race
condition, but here's the kicker: it is fine in production!. I wonder if it
has to do with hot-loading / how webpack loads things locally, since the
Port Cmd is passed correctly and ostensibly after the map has initialised,
and yet also fails to invalidateSize. The map does not have the correct size
in home if I remove the invalidateSize() from SetMarkers, which confirms
my suspicion that it is not a map FullscreenToggle issue.
