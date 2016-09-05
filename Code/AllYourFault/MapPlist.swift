//
//  MapPlist.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import Foundation
import MapKit

// A property list (.plist) value is anything that JSONSerialization can produce from JSON.
// This can be a number, string, array, dictionary with string keys, or nil, hence the optional type.
typealias PlistValue = AnyObject?

// A collection of common functions that map plist values to meaningful types.

final class MapPlist {

    class func int(_ value: PlistValue) -> Int? {
        return value as? Int
    }

    class func double(_ value: PlistValue) -> Double? {
        return value as? Double
    }

    class func string(_ value: PlistValue) -> String? {
        return value as? String
    }

    // Expects a double representing a Unix Epoch date.
    class func date(unixTime value: PlistValue) -> Date? {
        if let milliseconds = MapPlist.double(value) {
            return Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0)
        } else {
            return nil
        }
    }

    // Expects an array of doubles representing longitude, latitude, _.
    // Should we return the coordinate and depth as a tuple?
    class func coordinate2D(point value: PlistValue) -> CLLocationCoordinate2D? {
        if let array = MapPlist.array(mapItem: MapPlist.double)(value) , array.count == 3 {
            return CLLocationCoordinate2D(latitude: array[1], longitude: array[0])
        } else {
            return nil
        }
    }

    class func dictionary(_ value: PlistValue) -> NSDictionary? {
        return value as? NSDictionary
    }

    // This function is curried so as to produce a mapping function for a given item type.
    // mapItem is used to map each item of the array.
    // When strict, if any item fails to map, the whole array will fail. Otherwise failed items are omitted.
    class func array<T>(_ strict: Bool = true, mapItem: @escaping (PlistValue) -> T?) -> (PlistValue) -> [T]? {
        return { value in
            if let array = value as? NSArray {
                var result: [T] = []

                for item in array {
                    if let mappedItem = mapItem(item as PlistValue) {
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
   
}
