"use strict";
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

  var linesLayer = L.geoJSON();
  linesLayer.addTo(map);

  var pnLayer = L.geoJSON(null, {
    pointToLayer: function (geoJsonPoint, latlng) {
      return L.circleMarker(latlng, { radius: 4, color: 'green', opacity: 0.5 });
    },
    onEachFeature: function (feature, layer) {
      var p = feature.properties;
      var latlng = layer.getLatLng().lat + ',' + layer.getLatLng().lng;
      var content =
        '<b>' + p.fld_naam_ramses + '</b>' +
        '<br /><br />' + p.fld_postcode_en_gemeente +
        '<br /><br />' + p.fld_actief_passief +
        '<br /><br />' +
        '<a href="https://www.google.com/maps/?daddr=' + latlng + '" target="_blank">Google Maps</a> | ' +
        '<a href="waze://?ll=' + latlng + '" target="_blank">Waze</a> | ' +
        '<a href="https://maps.apple.com/?daddr=' + latlng + '" target="_blank">Apple</a>';
      layer.bindPopup(content);
      layer.on({
        mouseover: function() {
          layer.setStyle({ radius: 6, opacity: 1.0 });
        },
        mouseout: function() {
          layer.setStyle({ radius: 4, opacity: 0.5 });
        }
      });
    }
  });

  var baseLayers = {
    Grey: tiles
  };
  var overlays = {
    Tracks: linesLayer,
    'Level crossings': pnLayer
  };
  L.control.layers(baseLayers, overlays).addTo(map);

  $.getJSON('api/get-lines', function (data) {
    linesLayer.addData(data);
  });

  $.getJSON('api/get-pn', function (data) {
    pnLayer.addData(data);
  });

  var lgLoc = L.layerGroup();
  lgLoc.addTo(map);

  // map.locate({ setView: true, maxZoom: 14 });
  L.control.locate().addTo(map);

  map.on('click', getKp);
  map.on('locationfound', getKp);

  function getKp(e) {
    lgLoc.clearLayers();
    if (e.type === 'click') {      
      var here = L.circleMarker(e.latlng, { radius: 6 });
      here.bindPopup(
        '<p>' +
        'You clicked here' +
        '<br />' + e.latlng.lat.toFixed(6) + ',' + e.latlng.lng.toFixed(6) +
        '</p>'
      );
      lgLoc.addLayer(here);
    }
    if (e.type === 'locationfound') {
      var radius = e.accuracy;
      var here = L.circle(e.latlng, { radius: radius });
      here.bindPopup(
        '<p>' +
        'You are within ' + radius + ' meters from this point' +
        '<br />' + e.latlng.lat.toFixed(6) + ',' + e.latlng.lng.toFixed(6) +
        '</p>'
      );      
      lgLoc.addLayer(here);
    }
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
              '<br />KP: <b>' + p.measure.toFixed() + '</b>' +
              '<br />' + layer.getLatLng().lat.toFixed(6) + ',' + layer.getLatLng().lng.toFixed(6) +
              '<br />Distance from ' + e.type + ': ' + p.distance.toFixed() + ' m' +
              '</p>';
            return content;
          });
          lgLoc.addLayer(marker);
          marker.openPopup();
        }
      }
    });
  }
});
