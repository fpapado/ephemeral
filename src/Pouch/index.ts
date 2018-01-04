import xs, { Stream } from 'xstream';
import PouchDB from 'pouchdb-browser';
import PouchAuth from 'pouchdb-authentication';
import { app } from 'ephemeral';
import { config } from 'config';
import { string2Hex } from '../util/util';
import { Either, unpack } from '@typed/either';
import {
  NewDocument,
  Document,
  EntryContent,
  Entry,
  ExistingDocument,
  DocumentID,
  ExportMethod,
  LoginUser,
  isEntry
} from './types';
import { Card } from '../export/types';

/* Module responsible for PouchDB init and access */

// TYPES
// NOTE: Need to add this s.t TS typechecks correctly
// and allows for PouchDB devtools integration
declare global {
  interface Window {
    PouchDB: typeof PouchDB;
  }
}

// MODEL
// NOTE: 'Model' is a misnomer given the rampant mutation happening inside
// the database, but I will take the symmetry over strict semantics.
// TODO: if there are other possible types of docs in DB, add to types.ts
// and create a union to hold them
interface Model {
  localDB: PouchDB.Database;
  remoteDB: PouchDB.Database;
  syncHandler?: PouchDB.Replication.Sync<Entry>;
}

let model: Model;

// INIT
export function initPouch(msg$: Stream<PouchMsg>): void {
  /* Set model, launch subscriptions */
  initModel().then(m => {
    model = m;

    // Command subscriptions
    msg$.debug().addListener({
      next: msg => update(msg),
      error: err => console.error(err),
      complete: () => console.log('completed')
    });

    // DB change subscriptions
    model.localDB
      .changes({ live: true, include_docs: true, since: 'now' })
      .on('change', info => {
        console.log('Something changed!', info);
        const { doc } = info;

        // Send all updates to the elm side, as appropriate
        // TODO: might want to batch things into one big updatedEntries
        if (doc && doc._deleted) {
          console.log('Deleted doc');
          app.ports.deletedEntry.send({ _id: doc._id });
        } else {
          console.log('Updated doc');
          app.ports.updatedEntry.send(doc);
        }
      })
      .on('complete', info => {
        console.log('Replication complete');
      })
      .on('error', (err: { error?: string; message?: string }) => {
        if (err.error === 'unauthorized') {
          console.error(err.message);
        } else {
          console.error('Unhandled error', err);
        }
      });
  });
}

function initModel(): Promise<Model> {
  // PouchDB Devtools integration
  window.PouchDB = PouchDB;

  // Set up PouchDB
  PouchDB.plugin(PouchAuth);
  let localDB = new PouchDB('ephemeral');

  // Before checking logins, we use the base url to check _users and _sessions
  // After that, we customise using initRemoteDB() to include the user's db suffix
  // NOTE: there seems to be a bug(?), where leaving the naked URL in will
  // result in an error. Thus passing a doc path after (_users for convenience)
  // is required. This is fine because the DB url is overwritten afterwards.
  let url = `${config.couchUrl}_users`;
  let tempRemote = new PouchDB(url, { skip_setup: true });

  return getUserIfLoggedIn(tempRemote).then(res => {
    let remoteDB: PouchDB.Database<{}>,
      syncHandler: PouchDB.Replication.Sync<{}>;

    return unpack(
      function(err) {
        console.warn(err, 'Will not sync.');
        return { localDB, remoteDB };
      },
      function(username) {
        console.info('User is logged in, will sync.');

        // Configure remote as appropriate for each environment
        if (config.environment == 'production') {
          remoteDB = initRemoteDB(config.couchUrl, {
            method: 'dbPerUser',
            username
          });
        } else {
          remoteDB = initRemoteDB(config.couchUrl, {
            method: 'direct',
            dbName: config.dbName
          });
        }
        // Set the sync handler and start sync
        syncHandler = syncRemote(localDB, remoteDB);
        return { localDB, remoteDB, syncHandler };
      },
      res
    );
  });
}

// MSG
type Msg<MsgType, DataType = {}> = { msgType: MsgType; data: DataType };

export function Msg<A, B extends {}>(type: A, data: B): Msg<A, B> {
  return {
    msgType: type,
    data: data
  };
}

export type PouchMsg =
  | Msg<'LoginUser', LoginUser> // User
  | Msg<'LogoutUser'>
  | Msg<'CheckAuth'>
  | Msg<'UpdateEntry', ExistingDocument<{}>> // Entry
  | Msg<'SaveEntry', NewDocument<EntryContent>> // Entry
  | Msg<'DeleteEntry', DocumentID> // EntryId
  | Msg<'ListEntries'>
  | Msg<'ExportCards', ExportMethod>;

// UPDATE
function update(msg: PouchMsg) {
  switch (msg.msgType) {
    case 'LoginUser':
      loginUser(model.remoteDB, msg.data);
      break;
    case 'LogoutUser':
      logOut(model.remoteDB);
      break;
    case 'CheckAuth':
      checkAuth(model.remoteDB);
      break;
    case 'UpdateEntry':
      updateEntry(model.localDB, msg.data);
      break;
    case 'SaveEntry':
      saveEntry(model.localDB, msg.data);
      break;
    case 'DeleteEntry':
      deleteEntry(model.localDB, msg.data);
      break;
    case 'ListEntries':
      listEntries(model.localDB);
      break;
    case 'ExportCards':
      exportCards(model.localDB, msg.data);
    default:
      console.warn('Leaflet Port command not recognised');
  }
}

// Update functions
function loginUser(remoteDB: PouchDB.Database<{}>, user: LoginUser) {
  console.log('Got user to log in', user.username);

  let { username, password } = user;

  remoteDB.logIn(username, password).then(res => {
    console.log('Logged in!', res);

    if (res.ok === true) {
      let { name } = res;
      app.ports.logIn.send({ username: name });
      startSync(name);
      return name;
    } else {
      // TODO: send to Elm / show toast
      console.error('Something went wrong when logging in');
    }
  });
}

function startSync(username: string) {
  // TODO: set model
  // Start replication, assign to global remote and handler
  let remoteDB;
  if (config.environment == 'production') {
    remoteDB = initRemoteDB(config.couchUrl, {
      method: 'dbPerUser',
      username: name
    });
  } else {
    remoteDB = initRemoteDB(config.couchUrl, {
      method: 'direct',
      dbName: config.dbName
    });
  }

  try {
    // Return a sync handler
    return syncRemote(model.localDB, remoteDB);
  } catch (err) {
    // TODO: send error over port
    if (err.name === 'unauthorized') {
      console.warn('Unauthorized');
    } else {
      console.error('Other error', err);
    }
  }
}

function logOut(remoteDB: PouchDB.Database<{}>) {
  console.log('Got message to log out');

  // Cancel sync before logging out, otherwise we don't have auth
  console.info('Stopping sync');
  // TODO: decide where syncHandler should live
  cancelSync(model.syncHandler);

  remoteDB.logOut().then(res => {
    // res: {"ok": true}
    console.log('Logging user out');
    if (res.ok) {
      app.ports.logOut.send(res);
    } else {
      console.error('Something went wrong logging user out');
    }
  });
}

function checkAuth(remoteDB: PouchDB.Database<{}>) {
  console.log('Checking Auth');

  remoteDB
    .getSession()
    .then(res => {
      if (!res.userCtx.name) {
        // res: {"ok": true}
        console.log('No user logged in, logging user out', res);
        let { ok } = res;
        app.ports.logOut.send({ ok: ok });
      } else {
        console.log('User is logged in', res);
        let { name } = res.userCtx;
        // TODO: in the future, will need to add more info
        app.ports.logIn.send({ username: name });
      }
    })
    .catch(err => {
      console.error('Error checking Auth', err);
    });
}

function updateEntry(db: PouchDB.Database<{}>, data: ExistingDocument<{}>) {
  console.log('Got entry to update', data);

  let { _id } = data;
  console.log(_id);

  db
    .get(_id)
    .then(doc => {
      // NOTE: We disregard the _rev from Elm, to be safe
      let { _rev } = doc;

      let newDoc = Object.assign(doc, data);
      newDoc._rev = _rev;

      return db.put(newDoc);
    })
    .then(res => {
      db.get(res.id).then(doc => {
        console.log('Successfully updated', doc);
        app.ports.updatedEntry.send(doc);
      });
    })
    .catch(err => {
      console.error('Failed to update', err);
      // TODO: Send back over port that Err error
    });
}

function saveEntry(db: PouchDB.Database<{}>, data: NewDocument<EntryContent>) {
  console.log('Got entry to create', data);
  // TODO: play with this
  let meta = { type: 'entry' as 'entry' };
  let doc: Entry = Object.assign(data, meta);

  db
    .post(doc)
    .then(res => {
      db.get(res.id).then(doc => {
        console.log('Successfully created', doc);
        app.ports.updatedEntry.send(doc);
      });
    })
    .catch(err => {
      console.error('Failed to create', err);
      // TODO: Send back over port that Err error?
    });
}

function deleteEntry(db: PouchDB.Database, id: DocumentID) {
  console.log('Got entry to delete', id);

  db
    .get(id)
    .then(doc => {
      return db.remove(doc);
    })
    .then(res => {
      console.log('Successfully deleted', id);
      app.ports.deletedEntry.send({ _id: id });
    })
    .catch(err => {
      console.error('Failed to delete', err);
      // TODO: Send back over port that Err error
    });
}

function listEntries(db: PouchDB.Database<{}>) {
  console.log('Will list entries');
  let docs = db.allDocs({ include_docs: true }).then(docs => {
    let entries = docs.rows.map(row => row.doc);
    console.log('Listing entries', entries);

    app.ports.getEntries.send(entries);
  });
}

function exportCards(db: PouchDB.Database<Entry | {}>, method: ExportMethod) {
  import(/* webpackChunkName: "export" */ '../export/export').then(
    ({ exportCardsCSV, exportCardsAnki }) => {
      db.allDocs({ include_docs: true }).then(docs => {
        let entries = docs.rows
          .map(row => row.doc)
          .filter(row => row !== undefined && isEntry(row)) as Card[]; // assertion required to convince of undefined removal
        if (method === 'CSV') {
          exportCardsCSV(entries);
        } else if (method === 'ANKI') {
          exportCardsAnki(entries);
        }
      });
    }
  );
}

// Utils
type UserResult = Either<UserError, string>;
type UserError = 'NOT_LOGGED_IN' | 'ERROR_CONNECTING';
function getUserIfLoggedIn(
  remoteDB: PouchDB.Database<{}>
): Promise<UserResult> {
  let loggedIn = remoteDB
    .getSession()
    .then(res => {
      if (!res.userCtx.name) {
        return Either.left('NOT_LOGGED_IN' as 'NOT_LOGGED_IN');
      } else {
        return Either.of(res.userCtx.name);
      }
    })
    .catch(err => {
      return Either.left('ERROR_CONNECTING' as 'ERROR_CONNECTING');
    });
  return loggedIn;
}

function syncRemote(
  localDB: PouchDB.Database,
  remoteDB: PouchDB.Database
): PouchDB.Replication.Sync<{}> {
  console.info('Starting sync');

  let syncHandler = localDB.sync(remoteDB, {
    live: true,
    retry: true
  });
  return syncHandler;
}

function cancelSync(handler?: PouchDB.Replication.Sync<{}>) {
  if (!!handler) {
    // TODO: handle errors (lol)
    handler.cancel();
  }
  return true;
}

// Utils
type DBInitParams =
  | { method: 'direct'; dbName: string }
  | { method: 'dbPerUser'; username: string };

function initRemoteDB(
  couchUrl: string,
  initParams: DBInitParams
): PouchDB.Database {
  let dbName;

  /* Using db-per-user in production, so we must figure out the user's db.
    The couch-per-user plugin makes a DB of the form:
      userdb-{hex username}
  */
  if (initParams.method === 'dbPerUser') {
    dbName = 'userdb-' + string2Hex(initParams.username);
  } else {
    dbName = initParams.dbName;
  }

  let url = couchUrl + dbName;
  let remoteDB = new PouchDB(url, { skip_setup: true });

  return remoteDB;
}
