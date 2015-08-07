//
//  MapPlist.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import Foundation
import MapKit

// A property list (.plist) value is anything that NSJSONSerialization can produce from JSON.
// This can be a number, string, array, dictionary with string keys, or nil, hence the optional type.
typealias PlistValue = AnyObject?

// A collection of common functions that map plist values to meaningful types.

final class MapPlist {

    class func int(value: PlistValue) -> Int? {
        return value as? Int
    }

    class func double(value: PlistValue) -> Double? {
        return value as? Double
    }

    class func string(value: PlistValue) -> String? {
        return value as? String
    }

    // Expects a double representing a Unix Epoch date.
    class func dateWithUnixTime(value: PlistValue) -> NSDate? {
        if let milliseconds = MapPlist.double(value) {
            return NSDate(timeIntervalSince1970: NSTimeInterval(milliseconds) / 1000.0)
        } else {
            return nil
        }
    }

    // Expects an array of doubles representing longitude, latitude, _.
    // Should we return the coordinate and depth as a tuple?
    class func coordinate2DWithPoint(value: PlistValue) -> CLLocationCoordinate2D? {
        if let array = MapPlist.array(mapItem: MapPlist.double)(value) where array.count == 3 {
            return CLLocationCoordinate2D(latitude: array[1], longitude: array[0])
        } else {
            return nil
        }
    }

    class func dictionary(value: PlistValue) -> [String: AnyObject]? {
        return value as? [String: AnyObject]
    }

    // This function is curried so as to produce a mapping function for a given item type.
    // mapItem is used to map each item of the array.
    // When strict, if any item fails to map, the whole array will fail. Otherwise failed items are omitted.

    class func array<T>(strict: Bool = true, mapItem: PlistValue -> T?)(_ value: PlistValue) -> [T]? {
        if let array = value as? [AnyObject] {
            var result: [T] = []

            for item in array {
                if let mappedItem = mapItem(item) {
                    result.append(mappedItem)
                } else if strict {
                    return nil
                }
            }

            return result
        } else {
            return nil
        }
    }
   
}
