//
//  ViewController.swift
//  GeojsonViewer
//
//  Created by Brian Sanders on 5/14/18.
//  Copyright © 2018 Brian Sanders. All rights reserved.
//

import Cocoa
import MapKit

func makePoint(fromArray arr: [Double]) -> CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: arr[1], longitude: arr[0])
}

func makePolygon(points: [[[Double]]]) -> MKPolygon {
    let outerCoords = points[0].map(makePoint)
    var innerPolys: [MKPolygon]? = nil
    
    if points.count > 1 {
        innerPolys = points.dropFirst().map {
            let coords = $0.map(makePoint)
            return MKPolygon(coordinates: coords, count: coords.count)
        }
    }
    
    return MKPolygon(coordinates: outerCoords, count: outerCoords.count, interiorPolygons: innerPolys)
}

func makeMKOverlay(from geometry: Geom) -> MKOverlay? {
    switch geometry {
    case .point(_):
        // Draw something at the point -- a marker?
        return nil
    case .lineString(let points):
        let coords = points.map(makePoint)
        return MKPolyline(coordinates: coords, count: coords.count)
    case .polygon(let points):
        return makePolygon(points: points)
    default:
        return nil
    }
}

func makeMKOverlays(from feature: GeoFeature) -> [MKOverlay] {
    switch feature {
    case .feature(geometry: let geom, properties: _, id: _):
        if let geom = geom, let overlay = makeMKOverlay(from: geom) {
            return [overlay]
        } else {
            return [ ]
        }
    case .featureCollection(features: let features, properties: _, id: _):
        return features.flatMap(makeMKOverlays)
    }
}

class ViewController: NSViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
    }
    
    func refresh(rootFeature: GeoFeature) {
        let overlays = makeMKOverlays(from: rootFeature)
        let bounds = overlays.reduce(MKMapRectNull) { MKMapRectUnion($0, $1.boundingMapRect) }
        
        mapView.addOverlays(overlays)
        
        if !MKMapRectIsNull(bounds) {
            mapView.setVisibleMapRect(bounds, edgePadding: NSEdgeInsets(top: 1, left: 1, bottom: 1, right: 1), animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let poly = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: poly)
            renderer.strokeColor = NSColor.red
            renderer.lineWidth = 2
            renderer.fillColor = NSColor.red.withAlphaComponent(0.5)
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
}

