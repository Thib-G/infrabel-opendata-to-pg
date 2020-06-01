$(document).ready(function() {
  var mapboxKey = 'pk.eyJ1IjoidGhpYi1nIiwiYSI6ImNrOGdjeGJrYzAwYmwzbW1zd2htem11c2wifQ.SvlrQtH0K-uFxYe1Y-yhDg';
  var center = L.latLng([50.465841, 4.857634]);
  var zoom = 8;
  var map = L.map('map', {
    center: center,
    zoom: zoom
  });
  var tiles = L.tileLayer('https://api.mapbox.com/styles/v1/mapbox/light-v10/tiles/{z}/{x}/{y}{r}?access_token=' + mapboxKey,
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
    $.ajax({
      type: 'POST',
      url: 'api/get-kp',
      data: JSON.stringify({ lat: e.latlng.lat, lng: e.latlng.lng }),
      dataType: 'json',
      contentType: 'application/json',
      success: function (data) {
        if (data) {
          var marker = L.geoJSON(data);
          marker.bindPopup(function (layer) {
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
          lg.addLayer(marker);
          marker.openPopup();
        }
      }
    });
  });
});
