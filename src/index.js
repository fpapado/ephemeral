'use strict';

import L from 'leaflet';
import PouchDB from 'pouchdb-browser';
import * as OfflinePluginRuntime from 'offline-plugin/runtime';

require('./assets/css/styles.css');

OfflinePluginRuntime.install({
  onUpdating: () => {
    console.log('SW Event:', 'onUpdating');
  },
  onUpdateReady: () => {
    console.log('SW Event:', 'onUpdateReady');
    // Tells to new SW to take control immediately
    runtime.applyUpdate();
  },
  onUpdated: () => {
    console.log('SW Event:', 'onUpdated');
    // Reload the webpage to load into the new version
    window.location.reload();
  },

  onUpdateFailed: () => {
    console.log('SW Event:', 'onUpdateFailed');
  }
});

const Elm = require('./Main');

window.PouchDB = PouchDB;
PouchDB.plugin(require('pouchdb-authentication'));

let db = new PouchDB('ephemeral');
let remoteDB= new PouchDB('http://localhost:5984/ephemeral', {skip_setup: true});

remoteDB.login('fotis', '123')
  .then(res => {
    console.log('Logged in!', res);
  })
  .catch(err => {
    if (err.name === 'unauthorized') {
      console.log('Unauthorized');
    } else {
      console.log('Other error', err);
    }
  });

remoteDB.info()
  .then(res => {
    console.log("Got info", res);
  })
  .catch(err => {
    console.log("Info error", err);
  });

let syncHandler = db.sync(remoteDB, {
  live: true,
  retry: true,
}).on('change', info => {
  // something changed
  console.info("Something changed!", info);

  let { change, direction } = info;

  if (direction === 'pull'){
    change.docs.forEach(doc => {
      // TODO: find whether the document is new or not
      // might want to do this on the elm-side?
      app.ports.updatedEntry.send(doc);
    });
  }

  // TODO: destructure change, send doc to Elm
  // |> if "push" vs if "pull"
  // |> include_docs
}).on('paused', info => {
  // replication was paused, usually connection loss
  console.log("Replication paused");
}).on('active', info => {
  console.log("Replication resumed");
}).on('complete', info => {
  console.log("Replication complete");
}).on('error', err => {
  console.log("Unhandled error");
});


// TODO: get info from cancelReplication Port (or listen for logout event), pause replication
// syncHandler.cancel();


let mymap = L.map('mapid').setView([60.1719, 24.9414], 12);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(mymap);

let root = document.getElementById('root');
let app = Elm.Main.embed(root);

// -- Port Subscriptions --
let center;
let markers = {};

// mymap.on('move', (evt) => {
//   center = mymap.getCenter();
//   app.ports.getCenter.send([center.lat, center.lng])
// })

app.ports.setView.subscribe((data) => {
    mymap.setView.apply(mymap, data);
});

app.ports.setMarkers.subscribe((data) => {
    data.forEach((data, index) => {
      let [id, latLng, markerOptions, popupText] = data;

      markerOptions.icon = new L.Icon(markerOptions.icon)
      let marker = L.marker(latLng, markerOptions);

      marker.bindPopup(popupText);

      if(!markers.hasOwnProperty(id)) {
        marker.addTo(mymap);
        markers[id] = marker;
      }
      else {
        Object.assign(markers[id], marker);
      }
    })
});

app.ports.saveEntry.subscribe((data) => {
  console.log("Got entry to create", data);
  let meta = {"type": "entry"};
  let doc = Object.assign(data, meta);
  console.log(doc);

  db.post(doc)
    .then((res) => {
      db.get(res.id).then((doc) => {
        console.log("Successfully created", doc);
        app.ports.newEntry.send(doc);
      })
    })
    .catch((err) => {
    console.log("Failed to create", err);
    // TODO: Send back over port that Err error?
  })
});

app.ports.updateEntry.subscribe((data) => {
  console.log("Got entry to update", data);

  let {_id} = data;
  console.log(_id);

  db.get(_id).then((doc) => {
    // NOTE: We disregard the _rev from Elm, to be safe
    let {_rev} = doc;

    let newDoc = Object.assign(doc, data);
    newDoc._rev = _rev;

    return db.put(newDoc);
  }).then((res) => {
    db.get(res.id).then((doc) => {
      console.log("Successfully updated", doc);
      app.ports.updatedEntry.send(doc);
    })
  }).catch((err) =>{
    console.log("Failed to update", err);
    // TODO: Send back over port that Err error
  });

});

app.ports.listEntries.subscribe((str) => {
  console.log("Will list entries");
  let docs = db.allDocs({include_docs: true})
    .then(docs => {
      let entries = docs.rows.map(row => row.doc);
      console.log("Listing entries", entries);

      app.ports.getEntries.send(entries);
    });
});
