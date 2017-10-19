# Next
- [ ] Fonts, font loading, caching

- [ ] Fix session check
  - Currently, if logged in and page reloads, shown as logged out

More Navigation / routing stuff
- [ ] Style nav bar
- [ ] z-index nav bar and map
- [ ] Investigate Save/Commit and Geolocation
- [ ] Hide map where not needed (load dynamically, even?)

- [ ] Port branch
- [ ] DB helpers

http://jxnblk.com/hello-color/?c=a5dbf7

- [] Entry Page: Confirmation on success
  - [] In general, messaging service

- [ ] Make map additions directly in JS from the DB stream?
  - As in, make DB the single source of truth

# Port branch
- [ ] Port architecture, merging ports
  - [ ] e.g. could have:
    translatePouchUpdate : (Result String Entry -> msg) -> (Result Sting String -> msg) -> Value -> msg
    decodePouchUpdate updateMsg  deleteMsg fromPort = ...

  - [ ] pouchToElm, pouchFromElm
    -> API with cases etc there.
- [] toLeaflet; would require encoders for Leaflet.Types
  - [ ] move port encoders to Port?
- [ ] Debatable whether to propagate error in Request.Entry or return empty Dict
  - [ ] Generally, errors from Ports

# Settings Page
- [ ] DB url
- [ ] Default location

# Other ideas
- Page.initData Cmd convention? Would avoid having to send Request.listEntries directly on Main.elm etc.
- Style-elements?
- offline indicator
- Friendly 404

- [ ] Full(er) CRUD
  - [ ] Delete message
    - [ ] with confirmation message (initDelete, confirmDelete); modal?
  - [ ] Check marker removal in batch updates

- [ ] Add Edit back
  - [ ] Scroll up on edit
  - [ ] Cancel button on edit
  - [ ] Popup for editing?
  - [ ] Edit location
  - [ ] Edit time added

- Export:
  - [X] CSV (in-browser)
  - [X] Anki (remote/micro)
  - [ ] Specify deck name?
    - [ ] `micro-anki` extension
    - [ ] deck name would be important for import syncing, I think

- [ ] Factor things out of Page.Login into Request.Session or something (esp. login/logout and decoders)

- [ ] UX
  - [ ] Loading, disabled button
    - [ ] Basically RemoteData modelling
  - [ ] Offline/online status
  - [ ] Custom 404 and offline page
  - [ ] Message on successful login
    - [ ] Ditto on failed
  - [ ] Place get errors
  - [ ] Validations
  - [ ] Redirect on Login/Out
  - [ ] Replication status

- [ ] Signup?

- [ ] CheckAuth periodically?
  - [ ] Or, send "LogOut" over port if unauthorized/unauthenticated error?


- [ ] Organise JS
  - [ ] Clean console logs
  - [X] Prettier for JS
  - [ ] Split/organise JS
  - [ ] Add XO


- [ ] Better Pouch
  - [ ] Port architecture
  - [ ] API for Pouch access in JS
  - [ ] DateTime or custom based id? https://pouchdb.com/2014/06/17/12-pro-tips-for-better-code-with-pouchdb.html
  - [ ] Upsert https://pouchdb.com/guides/conflicts.html
  - [ ] Conflict resolution
    - [ ] Upsert?
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

- [ ] Port architecture
  - [ ] Single port per responsibility, parse on either side?
  - [ ] For instance, log in /out
  - [ ] Full CRUD

- [ ] Errors over ports when creation/deletion fails?

# More UI/UX
- [ ] UI/UX Pass
  - [ ] Error view, English
  - [ ] Show message on Geolocation error, that a default position was used
  - [ ] Dismiss errors
  - [ ] "Success" message
  - [ ] Flexbox for flight buttons
  - [ ] Packery with 4 items and 3 columns can be wonky
  - [ ] Later: Grid and fallbacks

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
- [ ] Bring-your-own DB
  - [ ] Generally, host-your-own option
  - [ ] Guide for this
  - [ ] "Deploy micro-anki to now" guide
  - [ ] Configurable micro-anki url
- [X] Export to Anki
- [ ] Translation Helper
- [ ] Large sync updates; markers?
- [ ] Move other marker operations to toLeaflet
  - Quite the effort atm, especially encoding everything manually
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
