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
        guard let dictionary = MapPlist.dictionary(value),
            let properties = MapPlist.dictionary(dictionary["properties"] as PlistValue),
            let identifier = MapPlist.string(properties["code"] as PlistValue),
            let date = MapPlist.date(unixTime: properties["time"] as PlistValue),
            let magnitude = MapPlist.double(properties["mag"] as PlistValue),
            let geometry = MapPlist.dictionary(dictionary["geometry"] as PlistValue),
            let coordinate = MapPlist.coordinate2D(point: geometry["coordinates"] as PlistValue) else
        {
            return nil
        }

        return Feature(identifier: identifier, date: date, coordinate: coordinate, magnitude: magnitude)
    }

}
