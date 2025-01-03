"use strict";
$(document).ready(function() {
  var mapboxKey = 'pk.eyJ1IjoidGhpYi1nIiwiYSI6ImNrOGdjeGJrYzAwYmwzbW1zd2htem11c2wifQ.SvlrQtH0K-uFxYe1Y-yhDg';
  var center = L.latLng([50.465841, 4.857634]);
  var zoom = 8;
  var map = L.map('map', {
    center: center,
    zoom: zoom
  });
  var attrib = '<i class="fa fa-github" aria-hidden="true"></i> <a href="https://github.com/Thib-G/infrabel-opendata-to-pg" target="_top">Source</a> |  &copy; <a href="https://opendata.infrabel.be" target="_top">Infrabel</a> ';
  var tiles = L.tileLayer('https://api.mapbox.com/styles/v1/mapbox/light-v10/tiles/{z}/{x}/{y}{r}?access_token=' + mapboxKey,
    {
      attribution: attrib + '&copy; <a href="https://www.mapbox.com/feedback/" target="_top">Mapbox</a> &copy; <a href="http://www.openstreetmap.org/copyright" target="_top">OpenStreetMap</a>',
      tileSize: 512,
      maxZoom: 18,
      zoomOffset: -1
    });
  tiles.addTo(map);

  var linesLayer = L.geoJSON(null, {
    style: { opacity: 0.4 },
    onEachFeature: function (feature, layer) {
      layer.on({
        mouseover: function() {
          layer.setStyle({ opacity: 1 });
        },
        mouseout: function() {
          layer.setStyle({ opacity: 0.4 });
        }
      });
    }
  });
  linesLayer.addTo(map);

  var pnLayer = L.geoJSON(null, {
    pointToLayer: function (geoJsonPoint, latlng) {
      return L.circleMarker(latlng, { radius: 4, color: 'green', opacity: 0.5 });
    },
    onEachFeature: function (feature, layer) {
      addPnPopup(feature, layer);
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

  var arrLayer = L.geoJSON(null, {
    onEachFeature: function (feature, layer) {
      layer.bindTooltip(feature.properties.arr_nr + ' ' + feature.properties.arr_name);
    }
  });

  var lciLayer = L.geoJSON(null, {
    pointToLayer: function (geoJsonPoint, latlng) {
      return L.circleMarker(latlng, { radius: 6, color: 'darkred', opacity: 0.5 });
    },
    onEachFeature: function (feature, layer) {
      addLciPopup(feature, layer);
      layer.on({
        mouseover: function() {
          layer.setStyle({ radius: 8, opacity: 1.0 });
        },
        mouseout: function() {
          layer.setStyle({ radius: 6, opacity: 0.5 });
        }
      });
    }
  });
  lciLayer.addTo(map);

  function addPnPopup (feature, layer) {
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
  }

  function addLciPopup (feature, layer) {
    var p = feature.properties;
    var latlng = layer.getLatLng().lat + ',' + layer.getLatLng().lng;
    var content =
      '<h4>' + p.name + '</h4>' +
      '<p>' + p.address + '</p>' +
      '<p>' +
      '<a href="https://www.google.com/maps/?daddr=' + latlng + '" target="_blank">Google Maps</a> | ' +
      '<a href="waze://?ll=' + latlng + '" target="_blank">Waze</a> | ' +
      '<a href="https://maps.apple.com/?daddr=' + latlng + '" target="_blank">Apple</a>' +
      '</p>';
    layer.bindPopup(content);
  }

  var baseLayers = {
    Grey: tiles
  };
  var overlays = {
    Tracks: linesLayer,
    'Level crossings': pnLayer,
    Arrondissements: arrLayer,
    LCIs: lciLayer
  };
  L.control.layers(baseLayers, overlays).addTo(map);

  $.getJSON('geo/lines.json', function (data) {
    linesLayer.addData(data);
  });

  $.getJSON('geo/pn.json', function (data) {
    pnLayer.addData(data);
    addSelect2(data);
  });

  $.getJSON('arr/arr.json', function (data) {
    arrLayer.addData(data);
  });

  $.getJSON('geo/clis.json', function (data) {
    lciLayer.addData(data);
  });

  var lgLoc = L.layerGroup();
  lgLoc.addTo(map);

  var fgSearchResult = L.featureGroup();
  fgSearchResult.addTo(map);

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
            var latlng = layer.getLatLng().lat + ',' + layer.getLatLng().lng;
            var content =
              '<p>' +
              'Track: <b>' + p.trackcode + '</b>' +
              '<br />KP: <b>' + p.measure.toFixed() + '</b>' +
              '<br />' + layer.getLatLng().lat.toFixed(6) + ',' + layer.getLatLng().lng.toFixed(6) +
              '<br />Distance from ' + e.type + ': ' + p.distance.toFixed() + ' m' +
              '<br /><br />' +
              '<a href="https://www.google.com/maps/?daddr=' + latlng + '" target="_blank">Google Maps</a> | ' +
              '<a href="waze://?ll=' + latlng + '" target="_blank">Waze</a> | ' +
              '<a href="https://maps.apple.com/?daddr=' + latlng + '" target="_blank">Apple</a>';
              '</p>';
            return content;
          });
          lgLoc.addLayer(marker);
          marker.openPopup();
        }
      }
    });
  }
  function addSelect2(geojson) {
    var options = geojson.features.map(function (feature) {
      return {
        id: feature.properties.ogc_fid,
        text: feature.properties.fld_naam_ramses
      };
    });
    $('.pn-select').select2({
      placeholder: 'Level crossing',
      allowClear: true,
      data: options
    }).val(null).trigger('change');
    $('.pn-select').on('select2:select', function (e) {
      fgSearchResult.clearLayers();
      var id = +e.params.data.id;
      var f = $.grep(geojson.features, function (feature) {
        return feature.properties.ogc_fid === id;
      })[0];
      var result = L.geoJSON(f, {
        onEachFeature: addPnPopup
      });
      fgSearchResult.addLayer(result);
      map.flyTo(fgSearchResult.getBounds().getCenter(), 15);
      result.openPopup();
    });
  }
});
