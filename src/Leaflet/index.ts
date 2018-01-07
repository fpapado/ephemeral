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
export type LeafletMsg =
  | SetView
  | FullScreenToggle
  | SetMarkers
  | RemoveMarker
  | OnInit;
type SetView = { type: 'SetView'; data: ViewData };
type FullScreenToggle = { type: 'FullScreenToggle'; data: MapToggleDir };
type SetMarkers = { type: 'SetMarkers'; data: MarkerData[] };
type RemoveMarker = { type: 'RemoveMarker'; data: MarkerID };
type OnInit = { type: 'OnInit' };

// UPDATE
// NOTE: these mutate things in place, since we're dealing with Leaflet.
// Perhaps, then, update is a misnomer.
// We could things immmutably (copy map, change things, return map, set
// model. That would be mostly pointless, imo.
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

    case 'FullScreenToggle':
      setFullScreen(msg.data);
      model.leafletMap.invalidateSize();
      break;

    case 'OnInit':
      model.leafletMap.invalidateSize();
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

type MapToggleDir = 'OnFullscreen' | 'OnNoFullscreen' | 'Off';

function setFullScreen(dir: MapToggleDir): void {
  let map = document.getElementById('mapid') as HTMLElement;

  let mapOn = () => map.classList.remove('dn');

  switch (dir) {
    case 'OnFullscreen':
      mapOn();
      map.classList.remove('h5', 'h6-ns');
      map.classList.add('h-fullmap', 'h-fullmap-ns');
      break;
    case 'OnNoFullscreen':
      mapOn();
      map.classList.remove('h-fullmap', 'h-fullmap-ns');
      map.classList.add('h5', 'h6-ns');
      break;
    case 'Off':
      map.classList.add('dn');
      break;
  }
}
