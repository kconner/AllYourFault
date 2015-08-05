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

    let identifier: String // properties.code
    let time: NSDate // properties.time
    let coordinate: CLLocationCoordinate2D // geometry.coordinates[0..<2]

    // TODO: assert that
    // properties.type == "earthquake"
    // geometry.type == "Point"

    static func mapPlistValue(value: PlistValue) -> Feature? {
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
