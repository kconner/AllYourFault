//
//  Feature.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import MapKit

// A seismic event reported by the USGS web service.

final class Feature: NSObject, MKAnnotation {

    let identifier: String // properties.code
    let date: NSDate // properties.time
    let coordinate: CLLocationCoordinate2D // geometry.coordinates[0..<2]
    let magnitude: Double // properties.mag

    // TODO: assert that
    // properties.type == "earthquake"
    // geometry.type == "Point"

    init(identifier: String, date: NSDate, coordinate: CLLocationCoordinate2D, magnitude: Double) {
        self.identifier = identifier
        self.date = date
        self.coordinate = coordinate
        self.magnitude = magnitude
    }

    static func mapPlistValue(value: PlistValue) -> Feature? {
        let m = MapPlist.self
        if let dictionary = m.dictionary(value),
            let properties = m.dictionary(dictionary["properties"]),
            let identifier = m.string(properties["code"]),
            let date = m.dateWithUnixTime(properties["time"]),
            let magnitude = m.double(properties["mag"]),
            let geometry = m.dictionary(dictionary["geometry"]),
            let coordinate = m.coordinate2DWithPoint(geometry["coordinates"]) {

            return Feature(identifier: identifier, date: date, coordinate: coordinate, magnitude: magnitude)
        } else {
            return nil
        }
    }

}
