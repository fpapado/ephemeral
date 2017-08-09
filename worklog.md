# TODO
[] Prototype local store
[] Routing with pages:
  [] List (map + items; current Main)
  [] Entry.Editor
  [] Entry.New
[] Add markers as words are added

# Base
Abstract Requests API
Offline detection and queueing
Localhost usage
Decide which fields are editable
Decide between pages
 |> Routing

# UI
[] Refresh/cleanup
[] "Success" message
[] Dismiss errors

# Later
[] Full CRUD
[] Authorization & Authentication
[] Location picker
[] Export to Anki
[] Merge markers and Entries?
[] Filter based on date, range
[X] Leaflet integration

# Dev
Consider elm and elm-live dev dependencies
NPM scripts for building, starting elm-live

# Refactoring
[] Figure out where to put encodeEntry, especially b/c of "config" construct (duplicated atm)
NOTE: A bit redundant to have "pages" atm. It is more like separating the updates, views etc. rather than routes (hence sharing a view in Main)

# Real Data
Might need to change ordering of id, encoding of floats
