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
    let date: Date // properties.time
    let coordinate: CLLocationCoordinate2D // geometry.coordinates[0..<2]
    let magnitude: Double // properties.mag

    init(identifier: String, date: Date, coordinate: CLLocationCoordinate2D, magnitude: Double) {
        self.identifier = identifier
        self.date = date
        self.coordinate = coordinate
        self.magnitude = magnitude
    }

    class func mapPlistValue(_ value: PlistValue) -> Feature? {
        let m = MapPlist.self
        if let dictionary = m.dictionary(value),
            let properties = m.dictionary(dictionary["properties"] as PlistValue),
            let identifier = m.string(properties["code"] as PlistValue),
            let date = m.dateWithUnixTime(properties["time"] as PlistValue),
            let magnitude = m.double(properties["mag"] as PlistValue),
            let geometry = m.dictionary(dictionary["geometry"] as PlistValue),
            let coordinate = m.coordinate2DWithPoint(geometry["coordinates"] as PlistValue) {

            return Feature(identifier: identifier, date: date, coordinate: coordinate, magnitude: magnitude)
        } else {
            return nil
        }
    }

}
