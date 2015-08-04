//
//  Feature.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import MapKit

// A seismic event reported by the USGS web service.

struct Feature {

    let coordinate: CLLocationCoordinate2D // geometry.coordinates[0..<2]
    let time: NSDate // property.time
    let identifier: Int // property.code

    // Expected:
    // properties.type == "earthquake"
    // geometry.type == "Point"

}
