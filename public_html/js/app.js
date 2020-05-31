$(document).ready(function() {
  var mapboxKey = 'pk.eyJ1IjoidGhpYi1nIiwiYSI6ImNrOGdjeGJrYzAwYmwzbW1zd2htem11c2wifQ.SvlrQtH0K-uFxYe1Y-yhDg';
  var center = L.latLng([50.465841, 4.857634]);
  var zoom = 8;
  var map = L.map('map', {
    center: center,
    zoom: zoom
  });
  var tiles = L.tileLayer('https://api.mapbox.com/styles/v1/mapbox/light-v10/tiles/{z}/{x}/{y}@2x?access_token=' + mapboxKey,
    {
      attribution: '&copy; <a href="https://www.mapbox.com/feedback/">Mapbox</a> &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      tileSize: 512,
      maxZoom: 18,
      zoomOffset: -1
    });
  tiles.addTo(map);

  var geojsonLayer = L.geoJSON();
  geojsonLayer.addTo(map);

  $.getJSON('api/get-lines', function (data) {
    geojsonLayer.addData(data);
  });

  var lg = L.layerGroup();
  lg.addTo(map);

  map.on('click', function(e) {
    lg.clearLayers();
    $.post('api/get-kp', { lat: e.latlng.lat, lng: e.latlng.lng }, function (data) {
      if (data) {
        var circle = L.geoJSON(data);
        circle.bindPopup(function (layer) {
          var p = layer.feature.properties;
          var content =
            '<p>' +
            'Track: <b>' + p.trackcode + '</b>' +
            '<br />KP: <b>' + p.measure + '</b>' +
            '<br />' + layer.getLatLng().lat.toFixed(6) + ',' + layer.getLatLng().lng.toFixed(6) +
            '<br />Distance from click: ' + p.distance.toFixed() + ' m' +
            '</p>';
          return content;
        });
        lg.addLayer(circle);
        circle.openPopup();
      }
    });
  }, 'json');
});
