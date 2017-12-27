import xs, { Stream } from 'xstream';
import { initLeaflet, LeafletMsg } from 'ephemeral/Leaflet/index';
import { initPouch, PouchMsg, Msg } from 'ephemeral/Pouch/index';
import * as OfflinePluginRuntime from 'offline-plugin/runtime';
import './assets/css/styles.scss';
import {
  NewDocument,
  Document,
  ExistingDocument,
  DocumentID,
  LoginUser
} from 'ephemeral/Pouch/types';
import { Main } from 'ephemeral/elm';

// Embed Elm
const root = document.getElementById('root') as HTMLElement;
export const app = Main.embed(root);

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

// -- Port Subscriptions --
// Initialise Leaflet module with a stream of Leaflet-related Messages from Elm
initLeaflet(
  xs.create({
    start: function(listener) {
      app.ports.toLeaflet.subscribe((msg: LeafletMsg) => {
        listener.next(msg);
      });
    },
    stop: function() {
      app.ports.toLeaflet.unsubscribe();
    }
  })
);

// Initialise Pouch module with a stream of Pouch-related Messages from Elm
// Currently an aggregagtion of ports, pending migration
initPouch(
  xs.createWithMemory({
    start: function(listener) {
      // TODO: find a non-silly way to do these
      app.ports.sendLogin.subscribe((user: LoginUser) =>
        listener.next(Msg('LoginUser' as 'LoginUser', user))
      );
      app.ports.sendLogout.subscribe((_: any) =>
        listener.next(Msg('LogoutUser' as 'LogoutUser', {}))
      );
      app.ports.checkAuthState.subscribe((_: any) =>
        listener.next(Msg('CheckAuth' as 'CheckAuth', {}))
      );
      app.ports.updateEntry.subscribe((entry: ExistingDocument<{}>) =>
        listener.next(Msg('UpdateEntry' as 'UpdateEntry', entry))
      );
      app.ports.saveEntry.subscribe((entry: NewDocument<{}>) =>
        listener.next(Msg('SaveEntry' as 'SaveEntry', entry))
      );
      app.ports.deleteEntry.subscribe((id: DocumentID) =>
        listener.next(Msg('DeleteEntry' as 'DeleteEntry', id))
      );
      app.ports.listEntries.subscribe((_: any) =>
        listener.next(Msg('ListEntries' as 'ListEntries', {}))
      );
    },
    stop: function() {
      app.ports.sendLogin.unsubscribe();
      app.ports.sendLogout.unsubscribe();
      app.ports.checkAuthState.unsubscribe();
      app.ports.updateEntry.unsubscribe();
      app.ports.saveEntry.unsubscribe();
      app.ports.deleteEntry.unsubscribe();
      app.ports.listEntries.unsubscribe();
    }
  })
);

// Other Ports
// app.ports.exportCards.subscribe(version => {
// // Lazy-load scripts for exporting cards
// import([> webpackChunkName: "export" <] './js/export').then(
// ({ exportCardsCSV, exportCardsAnki }) => {
// if (version === 'offline') {
// console.log('Will export');
// db.allDocs({ include_docs: true }).then(docs => {
// let entries = docs.rows.map(row => row.doc);
// exportCardsCSV(entries);
// });
// } else if (version === 'online') {
// db.allDocs({ include_docs: true }).then(docs => {
// let entries = docs.rows.map(row => row.doc);
// exportCardsAnki(entries);
// });
// }
// }
// );
// });
