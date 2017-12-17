import L from 'leaflet';
import xs, { Stream } from 'xstream';

// MODEL
interface Model {
  leafletMap?: any;
  markers?: any; // TODO; could use a set
}

let model: Model = {};

// INIT
export function initLeaflet(msg$: Stream<LeafletMsg>): void {
  // Set the initial model
  model = initModel();

  // Launch Subscriptions
  // TODO: Could we be passing the stream in here?
  msg$.debug().addListener({
    next: msg => update(msg),
    error: err => console.error(err),
    complete: () => console.log('completed')
  });
}

function initModel(): Model {
  const leafletMap = L.map('mapid', {
    preferCanvas: true
  }).setView([60.1719, 24.9414], 12);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(
    leafletMap
  );

  // Return initModel
  return { leafletMap: leafletMap, markers: {} };
}

// MSG
export type LeafletMsg = SetView | SetMarkers | RemoveMarker;
type SetView = { type: 'SetView'; data: any };
type SetMarkers = { type: 'SetMarkers'; data: any };
type RemoveMarker = { type: 'RemoveMarker'; data: any };

// UPDATE
// NOTE: these mutate things in place, since we're dealing with Leaflet.
// Perhaps, then, update is a misnomer.
// We could be doing things immmutably (copy map, change things, return map, set
// model.leafletMap = newMap), but I am not sure about the performance of that.
const update = (msg: LeafletMsg) => {
  switch (msg.type) {
    case 'SetView':
      setView(msg.data);
      break;

    case 'SetMarkers':
      setMarkers(msg.data);
      break;

    case 'RemoveMarker':
      removeMarker(msg.data);
      break;

    default:
      console.warn('Leaflet Port command not recognised');
  }
};

// Update functions
function setMarkers(data): void {
  data.forEach(({ id, latLng, markerOptions, popupText }, index) => {
    markerOptions.icon = new L.Icon(markerOptions.icon);
    let marker = L.marker(latLng, markerOptions);

    marker.bindPopup(popupText);

    if (!model.markers.hasOwnProperty(id)) {
      marker.addTo(model.leafletMap);
      model.markers[id] = marker;
    } else {
      Object.assign(model.markers[id], marker);
    }
  });
}

function removeMarker(data): void {
  let id = data;
  if (model.markers.hasOwnProperty(id)) {
    let marker = model.markers[id];
    model.leafletMap.removeLayer(marker);
  }
}

function setView({ center, zoom, options }): void {
  model.leafletMap.setView(center, zoom, options);
}
