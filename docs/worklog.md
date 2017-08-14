# TODO
- [X] PouchDB replication
  - [X] PouchDB-server locally
  - [X] Send changes on change
  - [X] PouchDB-auth
  - [X] Integrate login/logout and tracking in Elm
    - [X] LogIn -> port LogIn,
    - [X] sub LoggedIn -> LoggedIn,
    - [X] Show "log out" if user
    - [X] (UI/UX) "Logging in is optional, just tap" explanation on click
    - [X] LogOut -> port LogOut,
    - [X] sub LoggedOut -> LoggedOut
    - [X] loggedOut port message on checkAuth no user found
  - [X] Session storage/retrieval on reload?
    - [X] Try getSession on init
    - [N/A] Subscribe to cookie/store changes on key?
  - [X] Pouchdb-server syncs without login even
  - [X] Start sync only when loggedIn ->
    - [X] Factor out syncRemote() function
    - [X] When starting, use checkAuth().then(sync)
    - [X] Else, when logging in, then call syncRemote()
  - [X] Configure url based on environment

  - [X] db-per-user strategy
  - [X] Remove the /ephemeral suffix from url config if so
  - [X] initDB

  - [X] Use Dict instead of List for entries
  - [X] Html.lazy
  - [X] Html.keyed
  - [X] Batch marker addition when bulk entries
    - [X] Send AddMarkers directly

  - [ ] updateMarker Port architecture
  - [ ] remove marker

  - [ ] Full(er) CRUD
    - [ ] Delete message
      - [ ] with confirmation message (initDelete, confirmDelete); modal?
    - [X] Delete -> port Delete
    - [X] sub deletedEntry -> EntryDeleted
    - [X] Handle more sync events (e.g. "pull" _deleted_: true)
  - [ ] DateTime or custom based id? https://pouchdb.com/2014/06/17/12-pro-tips-for-better-code-with-pouchdb.html

  - [N/A] Could merge all the entry CRUD into "UpdatedEntry", where we index by id on the Elm side and just put the new thing in?
    Perhaps keep the deletion separate after all


# After "replication" branch
  - [ ] Related: Port architecture, merging ports
    - [ ] e.g. could have:
      translatePouchUpdate : (Result String Entry -> msg) -> (Result Sting String -> msg) -> Value -> msg
      decodePouchUpdate updateMsg  deleteMsg fromPort = ...
  - [ ] Debatable whether to propagate error in Request.Entry or return empty Dict
    - [ ] Generally, errors from Ports

- [ ] Factor things out of Page.Login into Request.Session or something (esp. login/logout and decoders)

- [ ] Add Edit back
  - [ ] Scroll up on edit
  - [ ] Cancel button on edit
  - [ ] Popup for editing?
  - [ ] Edit location
  - [ ] Edit time added

- [ ] UX
  - [ ] Message on successful login
    - [ ] Ditto on failed
  - [ ] Place get errors
  - [ ] Validations
  - [ ] Redirect on Login/Out
  - [ ] Replication status

- [ ] Signup?

- [ ] CheckAuth periodically?
  - [ ] Or, send "LogOut" over port if unauthorized/unauthenticated error?

- [ ] Routing with pages:
  - [ ] Main page + Login page
  - [ ] Map subs for subpages etc.
  - [ ] Extra, if needed:
    - [ ] List (map + items; current Main)
    - [ ] Entry.Editor
    - [ ] Entry.New


- [ ] Organise JS
  - [ ] Clean console logs
  - [X] Prettier for JS
  - [ ] Split/organise JS


- [ ] Better Pouch
  - [ ] API for Pouch access in JS
  - [ ] Upsert https://pouchdb.com/guides/conflicts.html
  - [ ] Conflict resolution
  - [ ] Error handling for Pouch
    - [ ] Particularly, replication errors over ports
      - [ ] On JS filter, send on port
      - [ ] On Elm accept { error: String } on port, display
        - [ ] Dismissable


- [ ] Handle errors from ports (Entry changes, Login)
  - [ ] How?

- [ ] update README

- [X] Merge NewEntry and UpdatedEntry (same functionality, since they both remove the entry with the id)
   - [ ] Eventually use Dict for entries

- [ ] Full CRUD
- [ ] Port architecture
  - [ ] Single port per responsibility, parse on either side?
  - [ ] For instance, log in /out

- [ ] Errors over ports when creation/deletion fails?

- [X] "Fly to": Helsinki, World, My Location

- [X] Use entry.id instead of indexed map in entries

- [X] Check SW updates


# Base
- Decide which fields are editable
- Decide between pages / routing

# UI/UX
- [ ] UI/UX Pass
  - [ ] Error view, English
  - [ ] Show message on Geolocation error, that a default position was used
  - [ ] Dismiss errors
  - [ ] "Success" message
  - [ ] Flexbox for flight buttons
  - [ ] Packery with 4 items and 3 columns can be wonky

- [ ] Refresh/cleanup
  - [X] 'Card' view for cards
    - [X] Grid?
    - [ ] Horizontal scroll?
  - [LATER] Flip view for cards
  - [LATER] Show/collapse information for cards etc.

- [ ] About page
- [ ] Spider spread for map
- [ ] Html.lazy check further

# Later
- [ ] Export to Anki
- [ ] Translation Helper
- [ ] Large sync updates; markers?
- [X] Own CouchDB?
- [ ] Bug in pouchdb-authentication? if only url is provided (no path after)
  then the xhr request goes to http://_users instead of http://dburl/_users
- [ ] More info on User, getUser() when checking auth, with id from getAuth()
- [X] PouchDB Auth
- [ ] migrations?
- [ ] Search
- [ ] Translation Helper
- [ ] Filtering on PouchDB messages
- [ ] Save revision of Entry; used for updates
- [ ] Timestamp for ID?
- [ ] Full CRUD
- [ ] Authorization & Authentication
- [ ] Location picker
- [ ] Merge markers and Entries?
- [ ] Filter based on date, range
- [ ] Critical CSS
  - [ ] PurifyCSS and Webpack
- [X] Leaflet integration
- [ ] Set up pouchdb-server locally and automatically with dev account


# Moonshot
- [ ] Have shared "channels" (db with group-write/group-red)

# Dev
- [X] NPM scripts for building, starting elm-live

# Refactoring
- [ ] View.elm signatures
- [ ] Figure out where to put encodeEntry, especially b/c of "config" construct (duplicated atm)
NOTE: A bit redundant to have "pages" atm. It is more like separating the updates, views etc. rather than routes (hence sharing a view in Main)
- [ ] When doing put(), I disregard the rev from the Elm side, since the get() has the latest already

// TODO: get info from cancelReplication Port (or listen for logout event), pause replication
// syncHandler.cancel();

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

# Setting up CouchDB
Links:

https://github.com/pouchdb-community/pouchdb-authentication#couchdb-authentication-recipes
http://docs.couchdb.org/en/latest/intro/security.html#authentication-database
https://www.digitalocean.com/community/tutorials/how-to-install-couchdb-and-futon-on-ubuntu-14-04
http://verbally.flimzy.com/configuring-couchdb-1-6-1-letsencrypt-free-ssl-certificate-debian-8-jessie/
