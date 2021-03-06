import 'ol/ol.css';
import { Map, View } from 'ol';
import { toLonLat, fromLonLat } from 'ol/proj';
import { skapa as skapaTopowebb, TopowebbVariant } from "./lager/Topowebb"
import { skapa as skapaOrtofoto } from "./lager/Ortofoto"
import { MarkeringLayer, skapa as skapaMarkering } from './lager/Markering';
import { Coordinate } from 'ol/coordinate';

export enum Bakgrundslager {
    ORTOFOTO = "ortofoto",
    TOPOWEBB = "topowebb_normal",
    TOPOWEBB_NEDTONAD = "topowebb_nedtonad"
}

export class Karta {
    map: Map;
    ortoLayer = skapaOrtofoto();
    topowebbLayer = skapaTopowebb(TopowebbVariant.NORMAL);
    topowebbnedtonadLayer = skapaTopowebb(TopowebbVariant.NEDTONAD);
    markeringLager: MarkeringLayer = skapaMarkering();

    constructor(elementId: string) {
        this.ortoLayer = skapaOrtofoto();
        this.topowebbLayer = skapaTopowebb(TopowebbVariant.NORMAL);
        this.topowebbnedtonadLayer = skapaTopowebb(TopowebbVariant.NEDTONAD);
        this.markeringLager = skapaMarkering();

        this.map = new Map({
            target: elementId,
            layers: [this.ortoLayer, this.topowebbLayer, this.topowebbnedtonadLayer, this.markeringLager],
            view: new View({
                center: [1909474.963338217, 8552634.820602188],
                zoom: 11
            })
        });
    }

    valjBakgrundslager(lager: Bakgrundslager): void {
        this.ortoLayer.setVisible(lager === Bakgrundslager.ORTOFOTO);
        this.topowebbLayer.setVisible(lager === Bakgrundslager.TOPOWEBB);
        this.topowebbnedtonadLayer.setVisible(lager === Bakgrundslager.TOPOWEBB_NEDTONAD);
    }

    placeraMarkering(longLat: Coordinate): void {
        this.markeringLager.placeraMarkering(longLat);
        this.markeringLager.setVisible(true);
    }

    onEnkelklick(callback: (a: Karta, b: Coordinate) => void) {
        const that = this;
        this.map.on('singleclick', function (event) {
            const lonLat = toLonLat(event.coordinate)
            callback(that, lonLat);
        });
    }
}

export function skapa(elementId: string): Karta {
    return new Karta(elementId);
}
