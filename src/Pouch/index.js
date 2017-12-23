"use strict";
exports.__esModule = true;
var PouchDB = require("pouchdb-browser");
var pouchdb_authentication_1 = require("pouchdb-authentication");
var ephemeral_1 = require("ephemeral");
var config_1 = require("config");
var util_1 = require("ephemeral/js/util");
var model = {
    localDB: undefined,
    remoteDB: undefined,
    syncHandler: undefined
};
// INIT
function initPouch(msg$) {
    // Set model, launch subscriptions
    initModel().then(function (m) {
        model = m;
        msg$.debug().addListener({
            next: function (msg) { return update(msg); },
            error: function (err) { return console.error(err); },
            complete: function () { return console.log('completed'); }
        });
    });
}
exports.initPouch = initPouch;
function initModel() {
    //@ts-ignore
    window['PouchDB'] = PouchDB; // needed for dev tools
    // Set up PouchDB
    PouchDB.plugin(pouchdb_authentication_1["default"]);
    var localDB = new PouchDB('ephemeral');
    // Before checking logins, we use the base url to check _users and _sessions
    // After that, we customise using initRemoteDB() to include the user's db suffix
    // NOTE: there seems to be a bug(?), where leaving the naked URL in will
    // result in an error. Thus passing a doc path after (_users for convenience)
    // is required. This is fine because the DB url is overwritten afterwards.
    var url = config_1.config.couchUrl + "_users";
    var tempRemote = new PouchDB(url, { skip_setup: true });
    return getUserIfLoggedIn(tempRemote).then(function (res) {
        var remoteDB, syncHandler;
        if (res.ok) {
            console.info('User is logged in, will sync.');
            // Configure remote as appropriate for each environment
            if (config_1.config.environment == 'production') {
                remoteDB = initRemoteDB(config_1.config.couchUrl, {
                    method: 'dbPerUser',
                    username: res.name
                });
            }
            else {
                remoteDB = initRemoteDB(config_1.config.couchUrl, {
                    method: 'direct',
                    dbName: config_1.config.dbName
                });
            }
            // Set the sync handler and start sync
            syncHandler = syncRemote(localDB, remoteDB);
            return { localDB: localDB, remoteDB: remoteDB, syncHandler: syncHandler };
        }
        else {
            console.warn(res.reason, 'Will not sync.');
            // TODO: Maybe?
            return { localDB: localDB, remoteDB: remoteDB };
        }
    });
}
function initRemoteDB(couchUrl, initParams) {
    var dbName;
    /* Using db-per-user in production, so we must figure out the user's db.
      The couch-per-user plugin makes a DB of the form:
        userdb-{hex username}
    */
    if (initParams.method === 'dbPerUser') {
        dbName = 'userdb-' + util_1.string2Hex(initParams.username);
    }
    else {
        dbName = initParams.dbName;
    }
    var url = couchUrl + dbName;
    var remoteDB = new PouchDB(url, { skip_setup: true });
    return remoteDB;
}
function Msg(type, data) {
    if (data === void 0) { data = {}; }
    return {
        msgType: type,
        data: data
    };
}
exports.Msg = Msg;
// UPDATE
function update(msg) {
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
    var username = user.username, password = user.password;
    remoteDB
        .login(username, password)
        .then(function (res) {
        console.log('Logged in!', res);
        if (res.ok === true) {
            var username_1 = res.username;
            ephemeral_1.app.ports.logIn.send({ username: username_1 });
            return username_1;
        }
    })
        .then(startSync(username));
}
function startSync(username) {
    // TODO: set model
    // Start replication, assign to global remote and handler
    var remoteDB;
    if (config_1.config.environment == 'production') {
        remoteDB = initRemoteDB(config_1.config.couchUrl, {
            method: 'dbPerUser',
            username: name
        });
    }
    else {
        remoteDB = initRemoteDB(config_1.config.couchUrl, {
            method: 'direct',
            dbName: config_1.config.dbName
        });
    }
    try {
        // Return a sync handler
        return syncRemote(model.localDB, remoteDB);
    }
    catch (err) {
        // TODO: send error over port
        if (err.name === 'unauthorized') {
            console.warn('Unauthorized');
        }
        else {
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
        .then(function (res) {
        // res: {"ok": true}
        console.log('Logging user out');
        ephemeral_1.app.ports.logOut.send(res);
    })["catch"](function (err) {
        console.error('Something went wrong logging user out', err);
    });
}
function checkAuth(remoteDB) {
    console.log('Checking Auth');
    remoteDB
        .getSession()
        .then(function (res) {
        if (!res.userCtx.name) {
            // res: {"ok": true}
            console.log('No user logged in, logging user out', res);
            var ok = res.ok;
            ephemeral_1.app.ports.logOut.send({ ok: ok });
        }
        else {
            console.log('User is logged in', res);
            var name_1 = res.userCtx.name;
            // TODO: in the future, will need to add more info
            ephemeral_1.app.ports.logIn.send({ username: name_1 });
        }
    })["catch"](function (err) {
        console.error('Error checking Auth', err);
    });
}
function updateEntry(db, data) {
    console.log('Got entry to update', data);
    var _id = data._id;
    console.log(_id);
    db
        .get(_id)
        .then(function (doc) {
        // NOTE: We disregard the _rev from Elm, to be safe
        var _rev = doc._rev;
        var newDoc = Object.assign(doc, data);
        newDoc._rev = _rev;
        return db.put(newDoc);
    })
        .then(function (res) {
        db.get(res.id).then(function (doc) {
            console.log('Successfully updated', doc);
            ephemeral_1.app.ports.updatedEntry.send(doc);
        });
    })["catch"](function (err) {
        console.error('Failed to update', err);
        // TODO: Send back over port that Err error
    });
}
function saveEntry(db, data) {
    console.log('Got entry to create', data);
    var meta = { type: 'entry' };
    var doc = Object.assign(data, meta);
    db
        .post(doc)
        .then(function (res) {
        db.get(res.id).then(function (doc) {
            console.log('Successfully created', doc);
            ephemeral_1.app.ports.updatedEntry.send(doc);
        });
    })["catch"](function (err) {
        console.error('Failed to create', err);
        // TODO: Send back over port that Err error?
    });
}
function deleteEntry(db, id) {
    console.log('Got entry to delete', id);
    db
        .get(id)
        .then(function (doc) {
        return db.remove(doc);
    })
        .then(function (res) {
        console.log('Successfully deleted', id);
        ephemeral_1.app.ports.deletedEntry.send({ _id: id });
    })["catch"](function (err) {
        console.error('Failed to delete', err);
        // TODO: Send back over port that Err error
    });
}
function listEntries(db) {
    console.log('Will list entries');
    var docs = db.allDocs({ include_docs: true }).then(function (docs) {
        var entries = docs.rows.map(function (row) { return row.doc; });
        console.log('Listing entries', entries);
        ephemeral_1.app.ports.getEntries.send(entries);
    });
}
// Utils
function getUserIfLoggedIn(remoteDB) {
    var loggedIn = remoteDB
        .getSession()
        .then(function (res) {
        if (!res.userCtx.name) {
            return { ok: false, reason: 'User is not logged in' };
        }
        else {
            return { ok: true, name: res.userCtx.name };
        }
    })["catch"](function (err) {
        return { ok: false, reason: 'Error in establishing connection' };
    });
    return loggedIn;
}
function syncRemote(localDB, remoteDB) {
    console.info('Starting sync');
    var syncHandler = localDB
        .sync(remoteDB, {
        live: true,
        retry: true
    })
        .on('change', function (info) {
        // something changed
        console.log('Something changed!', info);
        var change = info.change, direction = info.direction;
        // Send all updates to the elm side, as appropriate
        if (direction === 'pull') {
            // TODO: might want to batch things into one big updatedEntries
            change.docs.forEach(function (doc) {
                // TODO line 103 of replication defs could be like 421 of core
                if (doc._deleted) {
                    console.log('Deleted doc');
                    ephemeral_1.app.ports.deletedEntry.send({ _id: doc._id });
                }
                else {
                    ephemeral_1.app.ports.updatedEntry.send(doc);
                }
            });
        }
    })
        .on('paused', function (info) {
        // replication was paused, usually connection loss
        console.log('Replication paused');
    })
        .on('active', function () {
        console.log('Replication resumed');
    })
        .on('complete', function (info) {
        console.log('Replication complete');
    })
        .on('error', function (err) {
        if (err.error === 'unauthorized') {
            console.error(err.message);
        }
        else {
            console.error('Unhandled error', err);
        }
    });
    return syncHandler;
}
function cancelSync(handler) {
    // TODO: handle errors (lol)
    handler.cancel();
    return true;
}
