# TODO
[X] PouchDB replication
  [X] PouchDB-server locally
  [X] Send changes on change
  [X] PouchDB-auth
  [X] Integrate login/logout and tracking in Elm
    |> View on top
    |> [X] LogIn -> port LogIn,
       [X] sub LoggedIn -> LoggedIn,
       [X] Show "log out" if user
       [X] (UI/UX) "Logging in is optional, just tap" explanation on click
       [X] LogOut -> port LogOut,
       [X] sub LoggedOut -> LoggedOut
       [X] loggedOut port message on checkAuth no user found
  [X] Session storage/retrieval on reload?
    [X] Try getSession on init
    [N/A] Subscribe to cookie/store changes on key?
  [X] Pouchdb-server syncs without login even
  [X] Start sync only when loggedIn ->
    [X] Factor out syncRemote() function
    [X] When starting, use checkAuth().then(sync)
    [X] Else, when logging in, then call syncRemote()
  [X] Configure url based on environment

  [] Full(er) CRUD
    [] Delete |> with confirmation message (initDelete, confirmDelete); modal?
    [] Delete -> port Delete
    [] sub deletedEntry -> EntryDeleted
    [] Handle more sync events (e.g. "pull" _deleted_: true)
  [] DateTime or custom based id? https://pouchdb.com/2014/06/17/12-pro-tips-for-better-code-with-pouchdb.html
  [] Factor things out of Page.Login into Request.Session or something (esp. login/logout and decoders)

[] Add Edit back
  [] Scroll up on edit
  [] Cancel button on edit
  [] Popup for editing?
  [] Edit location
  [] Edit time added

[] UX
  [] Message on successful login
    [] Ditto on failed
  [] Redirect on Login/Out

[] Use Dict instead of List for entries
  [X] Could probably merge update and new entry Msg
  [] Could merge all the entry CRUD into "UpdatedEntry", where we index by id on the Elm side and just put the new thing in?
  [] Related: Port architecture

[] CheckAuth periodically?
  [] Or, send "LogOut" over port if unauthorized/unauthenticated error?

[] Routing with pages:
  [] Main page + Login page
  [] Map subs for subpages etc.
  [] Extra, if needed:
    [] List (map + items; current Main)
    [] Entry.Editor
    [] Entry.New


[] Organise JS
  [] Clean console logs
  [X] Prettier for JS
  [] Split/organise JS


[] Better Pouch
  [] API for Pouch access in JS
  [] Upsert https://pouchdb.com/guides/conflicts.html
  [] Conflict resolution
  [] Error handling for Pouch
    [] Particularly, replication errors over ports
      [] On JS: filter, send on port
      [] On elm: accept { error: String } on port, display
        [] Dismissable


[] Signup?
  [] Need the db-per-user strategy?
  [] Remove the /ephemeral suffix from url config if so

[] Handle errors from ports (Entry changes, Login)
  [] How?

[] update README

[X] Merge NewEntry and UpdatedEntry (same functionality, since they both remove the entry with the id)
  |> [] Eventually use Dict for entries

[] Full CRUD
[] Port architecture
  [] Single port per responsibility, parse on either side?
  [] For instance, log in /out

[] Errors over ports when creation/deletion fails?

[X] "Fly to": Helsinki, World, My Location

[X] Use entry.id instead of indexed map in entries

[X] Check SW updates


# Base
Decide which fields are editable
Decide between pages
 |> Routing

# UI/UX
[] UI/UX Pass
  [] Error view, English
  [] Show message on Geolocation error, that a default position was used
  [] Dismiss errors
  [] "Success" message
  [] Flexbox for flight buttons

[] Refresh/cleanup
  [X] 'Card' view for cards
    [X] Grid?
    [] Horizontal scroll?
  [LATER] Flip view for cards
  [LATER] Show/collapse information for cards etc.

[] About page
[] Spider spread for map
[] Html.lazy2

# Later
[X] Own CouchDB?
[] More info on User, getUser() when checking auth, with id from getAuth()
[X] PouchDB Auth
[] migrations?
[] Search
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
  [] PurifyCSS and Webpack
[X] Leaflet integration
[] Set up pouchdb-server locally and automatically with dev account


# Moonshot
[] Have shared "channels" (db with group-write/group-red)

# Dev
[X] NPM scripts for building, starting elm-live

# Refactoring
[] View.elm signatures
[] Figure out where to put encodeEntry, especially b/c of "config" construct (duplicated atm)
NOTE: A bit redundant to have "pages" atm. It is more like separating the updates, views etc. rather than routes (hence sharing a view in Main)
[] When doing put(), I disregard the rev from the Elm side, since the get() has the latest already

// TODO: get info from cancelReplication Port (or listen for logout event), pause replication
// syncHandler.cancel();


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

# Setting up CouchDB
Guide
IP bind
Proxy or not?
  SSL
Permissions and strategies
https://github.com/pouchdb-community/pouchdb-authentication#couchdb-authentication-recipes
http://docs.couchdb.org/en/latest/intro/security.html#authentication-database
https://www.digitalocean.com/community/tutorials/how-to-install-couchdb-and-futon-on-ubuntu-14-04
http://verbally.flimzy.com/configuring-couchdb-1-6-1-letsencrypt-free-ssl-certificate-debian-8-jessie/
