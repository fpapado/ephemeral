let root = document.getElementById('root');

let mymap = L.map('mapid').setView([60.1719, 24.9414], 12);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(mymap);

let app = Elm.Main.embed(root);

let center;
let markers = {};

mymap.on('move', (evt) => {
  center = mymap.getCenter();
  app.ports.getCenter.send([center.lat, center.lng])
})

app.ports.setView.subscribe((data) => {
    mymap.setView.apply(mymap, data);
});

app.ports.setMarkers.subscribe((data) => {
    data.forEach((data, index) => {
      let [id, latLng, markerOptions, popupText] = data;

      markerOptions.icon = new L.Icon(markerOptions.icon)
      let marker = L.marker(latLng, markerOptions);

      marker.bindPopup(popupText);

      if(!markers.hasOwnProperty(id)){
        marker.addTo(mymap);
      }
      markers[id] = marker;
    })
});
