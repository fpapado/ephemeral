import xs, { Stream } from 'xstream';
import PouchDB from 'pouchdb-browser';
import PouchAuth from 'pouchdb-authentication';
import { app } from 'ephemeral';
import { config } from 'config';
import { string2Hex } from 'ephemeral/js/util';

/* Module responsible for PouchDB init and access */

// MODEL
interface Model {
  localDB?: PouchDB.Database;
  remoteDB?: PouchDB.Database;
  syncHandler?: PouchDB.Replication.Sync<{}>;
}

let model: Model = {
  localDB: undefined,
  remoteDB: undefined,
  syncHandler: undefined
};

// INIT
export function initPouch(msg$: Stream<PouchMsg>): void {
  // Set model, launch subscriptions
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
      .changes({ live: true, include_docs: true })
      .on('change', info => {
        console.log('Something changed!', info);
        const { doc } = info;

        // Send all updates to the elm side, as appropriate
        // TODO: might want to batch things into one big updatedEntries
        if (doc._deleted) {
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
  //@ts-ignore
  window['PouchDB'] = PouchDB; // needed for dev tools

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
    let remoteDB, syncHandler;
    if (res.ok) {
      console.info('User is logged in, will sync.');

      // Configure remote as appropriate for each environment
      if (config.environment == 'production') {
        remoteDB = initRemoteDB(config.couchUrl, {
          method: 'dbPerUser',
          username: res.name
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
    } else {
      console.warn(res.reason, 'Will not sync.');
      // TODO: Maybe?
      return { localDB, remoteDB };
    }
  });
}

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

// MSG
type Msg<MsgType, DataType = {}> = { msgType: MsgType; data?: DataType };
export function Msg(type, data = {}) {
  return {
    msgType: type,
    data: data
  };
}

export type PouchMsg =
  | Msg<'LoginUser', any> // User
  | Msg<'LogoutUser'>
  | Msg<'CheckAuth'>
  | Msg<'UpdateEntry', any> // Entry
  | Msg<'SaveEntry', any> // Entry
  | Msg<'DeleteEntry', number> // EntryId
  | Msg<'ListEntries'>;

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
    default:
      console.warn('Leaflet Port command not recognised');
  }
}

// Update functions
function loginUser(remoteDB, user) {
  console.log('Got user to log in', user.username);

  let { username, password } = user;

  remoteDB
    .login(username, password)
    .then(res => {
      console.log('Logged in!', res);

      if (res.ok === true) {
        let { username } = res;
        app.ports.logIn.send({ username: username });
        return username;
      }
    })
    .then(startSync(username));
}

function startSync(username) {
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

function logOut(remoteDB) {
  console.log('Got message to log out');

  // Cancel sync before logging out, otherwise we don't have auth
  console.info('Stopping sync');
  // TODO: decide where syncHandler should live
  cancelSync(model.syncHandler);

  remoteDB
    .logout()
    .then(res => {
      // res: {"ok": true}
      console.log('Logging user out');
      app.ports.logOut.send(res);
    })
    .catch(err => {
      console.error('Something went wrong logging user out', err);
    });
}

function checkAuth(remoteDB) {
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

function updateEntry(db, data) {
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

function saveEntry(db, data) {
  console.log('Got entry to create', data);
  let meta = { type: 'entry' };
  let doc = Object.assign(data, meta);

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

function deleteEntry(db: PouchDB.Database, id) {
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

function listEntries(db) {
  console.log('Will list entries');
  let docs = db.allDocs({ include_docs: true }).then(docs => {
    let entries = docs.rows.map(row => row.doc);
    console.log('Listing entries', entries);

    app.ports.getEntries.send(entries);
  });
}

// Utils
function getUserIfLoggedIn(remoteDB) {
  let loggedIn = remoteDB
    .getSession()
    .then(res => {
      if (!res.userCtx.name) {
        return { ok: false, reason: 'User is not logged in' };
      } else {
        return { ok: true, name: res.userCtx.name };
      }
    })
    .catch(err => {
      return { ok: false, reason: 'Error in establishing connection' };
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

function cancelSync(handler) {
  // TODO: handle errors (lol)
  handler.cancel();
  return true;
}
