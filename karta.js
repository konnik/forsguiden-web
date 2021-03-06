import L from 'leaflet';

export function init(forsarGeo) {
    delete L.Icon.Default.prototype._getIconUrl;

    L.Icon.Default.mergeOptions({
    iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
    iconUrl: require('leaflet/dist/images/marker-icon.png'),
    shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
    });

    var customIcons = { 
        parkering : L.icon({
            iconUrl: require("./images/parkering.png"),
            iconSize:     [32, 32], // size of the icon
            iconAnchor:   [16, 16], // point of the icon which will correspond to marker's location
            popupAnchor:  [0, 0] // point from which the popup should open relative to the iconAnchor
            }),
        putin : L.icon({
            iconUrl: require("./images/putin.png"),
            iconSize:     [32, 32], // size of the icon
            iconAnchor:   [16, 16], // point of the icon which will correspond to marker's location
            popupAnchor:  [0, 0] // point from which the popup should open relative to the iconAnchor
            }),
        takeout : L.icon({
            iconUrl: require("./images/takeout.png"),
            iconSize:     [32, 32], // size of the icon
            iconAnchor:   [16, 16], // point of the icon which will correspond to marker's location
            popupAnchor:  [0, 0] // point from which the popup should open relative to the iconAnchor
            })
        }

    const gavle = [60.72975, 17.12693];
    const sverige = [63.031926, 15.451756]

    const map = L.map("map").setView(gavle, 11);

    const orto = L.tileLayer.wms("https://stompunkt.lantmateriet.se/maps/ortofoto/wms/v1.3", {
        layers: "Ortofoto_0.16,Ortofoto_0.25,Ortofoto_0.4,Ortofoto_0.5",
        // layers: "orto025,orto050",
        format: 'image/jpeg',
        version: '1.1.1',

        detectRetina: true
    });

    const streets = L.tileLayer('https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}', {
        attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
        maxZoom: 18,
        id: 'mapbox/streets-v11',
        tileSize: 512,
        zoomOffset: -1,
        accessToken: 'pk.eyJ1Ijoia29ubmlrIiwiYSI6ImNrZm13azN2ajFmMWozMHFoZ3F3czFneW0ifQ.6vvhWXlFXhso6ip9QPMyqA'
    });

    const topowebbUrl = "https://api.lantmateriet.se/open/topowebb-ccby/v1/wmts/token/{accessToken}/1.0.0/{layer}/default/3857/{z}/{y}/{x}.png"
    const topowebb = L.tileLayer(topowebbUrl, {
        accessToken: "b8913fdb-6555-3591-9cbb-6f1456ee1490",
        layer: "topowebb_nedtonad",
    maxZoom: 15,
    minZoom: 0,
    continuousWorld: true,
    attribution: '&copy; <a href="https://www.lantmateriet.se/en/">Lantmäteriet</a> Topografisk Webbkarta Visning, CCB',
    });

    const forsar = L.geoJSON(forsarGeo, {
        style: {
            color: "#0000ff",
            weight: 7
        },
        filter: (feature, layer) => {
            return feature.properties.typ == "fors";
        },
        onEachFeature:  (feature, layer) => {
            if (feature.properties.typ === "fors") {

                layer.bindTooltip(feature.properties.namn + " (" + feature.properties.vattendrag + ")", {
                    sticky : true
                });
            }
        }
    });

    const pois = L.geoJSON(forsarGeo, {
        style: {
            color: "#00ffff",
            weight: 5
        },
        filter: (feature, layer) => {
            return feature.properties.typ != "fors";
        },
        pointToLayer: function(feature, latlng) {
            return L.marker(latlng, {icon: customIcons[feature.properties.typ]});
        },
        onEachFeature:  (feature, layer) => {
            layer.bindTooltip(feature.properties.namn, {
                sticky : true
            });
        }
    });

    var baseMaps = {
        "Topowebb ": topowebb,
        "Ortofoto": orto,
        "Streets": streets
    };
    
    var overlayMaps = {
        "Forsar": forsar,
        "POIs": pois
    };
    
    topowebb.addTo(map);
    forsar.addTo(map);
    //pois.addTo(map);
    L.control.layers(baseMaps, overlayMaps).addTo(map);


    map.on('zoomend', function() {
        var zoomlevel = map.getZoom();
            if (zoomlevel  <14){
                if (map.hasLayer(pois)) {
                    map.removeLayer(pois);
                } else {
                    console.log("no point layer active");
                }
            }
            if (zoomlevel >= 14){
                if (map.hasLayer(pois)){
                    console.log("layer already added");
                } else {
                    map.addLayer(pois);
                }
            }
        console.log("Current Zoom Level =" + zoomlevel)
        });

    return map;
}

