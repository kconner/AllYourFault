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

    let identifier: String // property.code
    let time: NSDate // property.time
    let coordinate: CLLocationCoordinate2D // geometry.coordinates[0..<2]

    // Expected:
    // properties.type == "earthquake"
    // geometry.type == "Point"

    static func mapPlistValue(value: AnyObject?) -> Feature? {
        let m = MapPlist.self
        if let dictionary = m.dictionary(value),
            let properties = m.dictionary(dictionary["properties"]),
            let identifier = m.string(properties["code"]),
            let time = m.dateWithUnixTime(properties["time"]),
            let geometry = m.dictionary(dictionary["geometry"]),
            let coordinate = m.coordinate2DWithPoint(geometry["coordinates"]) {

            return Feature(identifier: identifier, time: time, coordinate: coordinate)
        } else {
            return nil
        }
    }

}
