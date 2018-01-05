import L from 'leaflet';
import xs, { Stream } from 'xstream';

// TYPES
interface MarkerData {
  id: string;
  latLng: L.LatLngExpression;
  // Extra attribute iconOptions since Elm only does JSON
  markerOptions: L.MarkerOptions & { iconOptions: L.IconOptions };
  popupText: string;
}

interface ViewData {
  center: L.LatLngExpression;
  zoom: number;
  options: L.ZoomPanOptions;
}

// Silly alias, but TS has equally silly boilerplate for proper simple types
type MarkerID = string;

// MODEL
interface Model {
  leafletMap: L.Map;
  markers: any; // TODO; could use a set
}

let model: Model;

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
// TODO: use existing Msg constructor
export type LeafletMsg = SetView | SetMarkers | RemoveMarker;
type SetView = { type: 'SetView'; data: ViewData };
type SetMarkers = { type: 'SetMarkers'; data: MarkerData[] };
type RemoveMarker = { type: 'RemoveMarker'; data: MarkerID };

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
function setMarkers(markers: MarkerData[]): void {
  markers.forEach(({ id, latLng, markerOptions, popupText }, index) => {
    // Reconstruct icon from iconOptions
    markerOptions.icon = new L.Icon(markerOptions.iconOptions);
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

function removeMarker(id: MarkerID): void {
  if (model.markers.hasOwnProperty(id)) {
    let marker = model.markers[id];
    model.leafletMap.removeLayer(marker);
  }
}

function setView({ center, zoom, options }: ViewData): void {
  model.leafletMap.setView(center, zoom, options);
}
