# TODO
[X] Webpack
[X] Demo dist
[X] Service worker caching
[X] SW tachyons etc.
[X] Manifest file

[X] Save after Geo Error anyway, with (0, 0)

[] Save revisions
[] updatePouch (use revision, add subscription to put)

[] Abstract away msg and flow for PouchDb
  [] Notify UI when Entry is created
  [] Add markers, update list as words are added


[] Check SW updates
[] Redundant create messages in Main, Request.Entry, Page.Entry

[] Full CRUD
[] Port architecture
  [] Single port per responsibility, parse on either side?

[] Clean console logs

[] Routing with pages:
  [] List (map + items; current Main)
  [] Entry.Editor
  [] Entry.New


# Base
Abstract Requests API
Offline detection and queueing
Localhost usage
Decide which fields are editable
Decide between pages
 |> Routing

# UI
[] Html.lazy2
[] Refresh/cleanup
[] "Success" message
[] Dismiss errors

# Later
[] Translation Helper
[] Filtering on PouchDB messages
[] Save revision of Entry; used for updates
[] Timestamp for ID?
[] Full CRUD
[] Authorization & Authentication
[] Location picker
[] Export to Anki
[] Merge markers and Entries?
[] Filter based on date, range
[] Critical CSS
[X] Leaflet integration

# Dev
[X] NPM scripts for building, starting elm-live

# Refactoring
[] View.elm signatures
[] Figure out where to put encodeEntry, especially b/c of "config" construct (duplicated atm)
NOTE: A bit redundant to have "pages" atm. It is more like separating the updates, views etc. rather than routes (hence sharing a view in Main)

# Real Data
Might need to change ordering of id, encoding of floats

# How to work offline
## Manual / optimistic
Always try to save online, add to queue and sync otherwise
  |> Would this be too much to track? We'd need ports etc. anyway, and to handle IndexedDB
    |> At that point, might as well use Pouch?

## PouchDB
I could "just" wrap PouchDB and treat it as my store, letting it do its thing
