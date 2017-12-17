import PouchDB from 'pouchdb-browser';
import PouchAuth from 'pouchdb-authentication';
import xs, { Stream } from 'xstream';
import { initLeaflet, LeafletMsg } from 'ephemeral/Leaflet/index';

import { config } from 'config';
import * as OfflinePluginRuntime from 'offline-plugin/runtime';
import './assets/css/styles.scss';

import { Main } from 'ephemeral/elm';
import { string2Hex } from './js/util';

// Embed Elm
const root = document.getElementById('root');
const app = Main.embed(root);

// Embed offline plugin runtime
OfflinePluginRuntime.install({
  onUpdating: () => {
    console.info('SW Event:', 'onUpdating');
  },
  onUpdateReady: () => {
    console.info('SW Event:', 'onUpdateReady');
    // Tells to new SW to take control immediately
    OfflinePluginRuntime.applyUpdate();
  },
  onUpdated: () => {
    console.info('SW Event:', 'onUpdated');
    // Reload the webpage to load into the new version
    window.location.reload();
  },

  onUpdateFailed: () => {
    console.error('SW Event:', 'onUpdateFailed');
  }
});

//@ts-ignore
window['PouchDB'] = PouchDB; // needed for dev tools

// Set up PouchDB
PouchDB.plugin(PouchAuth);
let db = new PouchDB('ephemeral');

// Before checking logins, we use the base url to check _users and _sessions
// After that, we customise using initDB() to include the user's db suffix
// NOTE: there seems to be a bug(?), where leaving the naked URL in will
// result in an error. Thus passing a doc path after (_users for convenience)
// is required. This is fine because the DB url is overwritten afterwards.
let url = config.couchUrl + '_users';
let remoteDB = new PouchDB(url, { skip_setup: true });

let syncHandler;

isUserLoggedIn(remoteDB).then(res => {
  if (res.ok) {
    console.info('User is logged in, will sync.');

    // Configure remote as appropriate for each environment
    let remoteDB;
    if (config.environment == 'production') {
      remoteDB = initDB(config.couchUrl, {
        method: 'dbPerUser',
        username: res.name
      });
    } else {
      remoteDB = initDB(config.couchUrl, {
        method: 'direct',
        dbName: config.dbName
      });
    }
    // Set the global sync handler
    syncHandler = syncRemote(db, remoteDB);
  } else {
    console.warn(res.reason, 'Will not sync.');
  }
});

type DBInitParams =
  | { method: 'direct'; dbName: string }
  | { method: 'dbPerUser'; username: string };

function initDB(couchUrl: string, initParams: DBInitParams) {
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
  let remote = new PouchDB(url, { skip_setup: true });

  return remote;
}

function isUserLoggedIn(remoteDB) {
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

function syncRemote(local, remote) {
  console.info('Starting sync');
  let syncHandler = local
    .sync(remote, {
      live: true,
      retry: true
    })
    .on('change', info => {
      // something changed
      console.log('Something changed!', info);

      let { change, direction } = info;

      if (direction === 'pull') {
        // TODO: might want to do this on the elm-side, and send things on single port?
        // TODO: might want to batch things into one big updatedEntries ...
        change.docs.forEach(doc => {
          if (doc._deleted) {
            console.log('Deleted doc');
            app.ports.deletedEntry.send({ _id: doc._id });
          } else {
            app.ports.updatedEntry.send(doc);
          }
        });
      }
    })
    .on('paused', info => {
      // replication was paused, usually connection loss
      console.log('Replication paused');
    })
    .on('active', info => {
      console.log('Replication resumed');
    })
    .on('complete', info => {
      console.log('Replication complete');
    })
    .on('error', err => {
      if (err.error === 'unauthorized') {
        console.error(err.message);
      } else {
        console.error('Unhandled error', err);
      }
    });
  return syncHandler;
}

function cancelSync(handler) {
  handler.cancel();
  return true;
}

// -- Port Subscriptions --
// Initialise Leaflet module with
// a stream of leaflet-related Messages from Elm
initLeaflet(
  xs.create({
    start: function(listener) {
      app.ports.toLeaflet.subscribe(msg => {
        listener.next(msg);
      });
    },
    stop: function() {
      app.ports.toLeaflet.unsubscribe();
    }
  })
);

// Other ports (legacy)
app.ports.sendLogin.subscribe(user => {
  console.log('Got user to log in', user.username);

  let { username, password } = user;

  remoteDB
    .login(username, password)
    .then(res => {
      console.log('Logged in!', res);

      if (res.ok === true) {
        let { name } = res;
        app.ports.logIn.send({ username: name });
        return name;
      }
    })
    .then(name => {
      // Start replication, assign to global remote and handler
      let remoteDB;
      if (config.environment == 'production') {
        remoteDB = initDB(config.couchUrl, {
          method: 'dbPerUser',
          username: name
        });
      } else {
        remoteDB = initDB(config.couchUrl, {
          method: 'direct',
          dbName: config.dbName
        });
      }

      // Set the global sync handler
      syncHandler = syncRemote(db, remoteDB);
    })
    .catch(err => {
      // TODO: send error over port
      if (err.name === 'unauthorized') {
        console.warn('Unauthorized');
      } else {
        console.error('Other error', err);
      }
    });
});

app.ports.sendLogout.subscribe(_ => {
  console.log('Got message to log out');

  // Cancel sync before logging out, otherwise we odn't have auth
  console.info('Stopping sync');
  cancelSync(syncHandler);

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
});

app.ports.checkAuthState.subscribe(data => {
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
});

app.ports.updateEntry.subscribe(data => {
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
});

app.ports.saveEntry.subscribe(data => {
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
});

app.ports.deleteEntry.subscribe(_id => {
  console.log('Got entry to delete', _id);

  db
    .get(_id)
    .then(doc => {
      return db.remove(doc);
    })
    .then(res => {
      console.log('Successfully deleted', _id);
      app.ports.deletedEntry.send({ _id: _id });
    })
    .catch(err => {
      console.error('Failed to delete', err);
      // TODO: Send back over port that Err error
    });
});

app.ports.listEntries.subscribe(str => {
  console.log('Will list entries');
  let docs = db.allDocs({ include_docs: true }).then(docs => {
    let entries = docs.rows.map(row => row.doc);
    console.log('Listing entries', entries);

    app.ports.getEntries.send(entries);
  });
});

app.ports.exportCards.subscribe(version => {
  // Lazy-load scripts for exporting cards
  import(/* webpackChunkName: "export" */ './js/export').then(
    ({ exportCardsCSV, exportCardsAnki }) => {
      if (version === 'offline') {
        console.log('Will export');
        db.allDocs({ include_docs: true }).then(docs => {
          let entries = docs.rows.map(row => row.doc);
          exportCardsCSV(entries);
        });
      } else if (version === 'online') {
        db.allDocs({ include_docs: true }).then(docs => {
          let entries = docs.rows.map(row => row.doc);
          exportCardsAnki(entries);
        });
      }
    }
  );
});
