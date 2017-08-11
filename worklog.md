# TODO
[X] Webpack
[X] Demo dist
[X] Service worker caching
[X] SW tachyons etc.
[X] Manifest file

[X] Save after Geo Error anyway, with (0, 0)

[X] Save revisions
[X] updatePouch

[X] Abstract away msg and flow for PouchDb
  [X] Notify UI when Entry is created
  [X] Notify UI when Entry is updated
    [X] Add markers based on entry.id
    [X] Properly handle markers on update ()
  [X] Cmd -> to Pouch
  [X] Sub -> message to Elm -> decode -> Cmd
  [X] Add markers, update list as words are added

  [] Scroll up on edit
  [] Cancel button on edit
  [] Popup for editing?

  [] Full CRUD
    [] Delete |> with confirmation message
  [] Port architecture
    [] Single port per responsibility, parse on either side?
  [] Redundant create messages in Main, Request.Entry, Page.Entry
  [] Errors over ports when creation/deletion fails?

[] GeoLocate user on start?
[] "Fly to": Helsinki, World, My Location

[] Use entry.id instead of indexed map in entries
[] Use Dict instead of List for entries
  |> Could probably merge update and new entry Msg at that point?

[] Check SW updates

[] Clean console logs
[] Prettier for JS
[] Split/organise JS

[] Routing with pages:
  [] List (map + items; current Main)
  [] Entry.Editor
  [] Entry.New


# Base
Decide which fields are editable
Abstract Requests API
Offline detection and queueing
Localhost usage
Decide between pages
 |> Routing

# UI
[] Spider spread for map
[] Html.lazy2
[] Refresh/cleanup
[] "Success" message
[] Dismiss errors

# Later
[] PouchDB Auth
[] DateTime or custom based id? https://pouchdb.com/2014/06/17/12-pro-tips-for-better-code-with-pouchdb.html
[] migrations?
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
[] When doing put(), I disregard the rev from the Elm side, since the get() has the latest already

# Real Data
Might need to change ordering of id, encoding of floats

# How to work offline
## Manual / optimistic
Always try to save online, add to queue and sync otherwise
  |> Would this be too much to track? We'd need ports etc. anyway, and to handle IndexedDB
    |> At that point, might as well use Pouch?

## PouchDB
I could "just" wrap PouchDB and treat it as my store, letting it do its thing

# Request module
I keeping the Requests for decoding the subs from ports in the Request, accepting a toMsg that will be triggered on the caller.
This allows some separation of concerns, and isn't unlike how Request keeps the Http requests without doing the actual sending, but allowing to specify which Msg will be generated.
