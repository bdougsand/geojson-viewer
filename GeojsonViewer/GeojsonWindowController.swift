//
//  GeojsonWindowController.swift
//  GeojsonViewer
//
//  Created by Brian Sanders on 5/14/18.
//  Copyright © 2018 Brian Sanders. All rights reserved.
//

import Cocoa

class GeojsonWindowController: NSWindowController {
    func refresh(rootFeature: GeoFeature) {
        if let mapController = contentViewController as? ViewController {
            mapController.refresh(rootFeature: rootFeature)
        }
    }
}
