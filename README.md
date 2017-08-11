# Ephemeral
TODO: Update with webpack info
TODO: Update with PouchDB info

Elm app for taking notes of words, tracking time added and location.
Also includes offline functionality and syncing.

## Development
Install `elm` and `elm-live`:
```shell
npm install -g elm elm-live
```

Build everything:
```shell
elm-live --output=elm.js src/Main.elm --pushstate --open --debug
```

## Development Data
A local server with dev data is created using `json-server`.
The data is generated using `faker`, in `mock/generate.js`.
In order to spin up the API server at localhost:3000, run:
```shell
npm install
npx json-server --watch mock/generate.js --routes mock/routes.json
```

The Elm codes knows to hit this endpoint from `src/Request/Helpers.elm`; feel free to change to suit your needs.

WIP: configure this automatically for production!

