//
//  APIEndpoints.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import Foundation

// Factory methods for common endpoints.
// These would be in an extension on the APIRequest class if it didn't take type parameters.

final class APIEndpoints {

    static func allEarthquakesRequest() -> APIRequest<[Feature]> {
        let url = URLWithPath("http://ehp2-earthquake.wr.usgs.gov/fdsnws/event/1/query",
            parameters: ["format": "geojson",
                "jsonerror": "true",
                "eventtype": "earthquake"])

        return APIRequest<[Feature]>(URL: url,
            successKey: "features",
            mapSuccessValue: MapPlist.array(Feature.mapPlistValue))
    }

    static func failingRequest() -> APIRequest<[Feature]> {
        let url = URLWithPath("http://ehp2-earthquake.wr.usgs.gov/fdsnws/event/1/query",
            parameters: ["format": "geojson",
                "jsonerror": "true",
                "starttime": "garbagevalue"])

        return APIRequest<[Feature]>(URL: url,
            successKey: "features",
            mapSuccessValue: MapPlist.array(Feature.mapPlistValue))
    }

    // MARK: Helpers

    private static func URLWithPath(path: String, parameters: [String: String] = [:]) -> NSURL {
        let URL: NSURL?
        if parameters.count == 0 {
            URL = NSURL(string: path)
        } else {
            let queryItems = map(parameters) { (key, value) -> String in
                if let escapedValue = value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet()) {
                    return "\(key)=\(escapedValue)"
                } else {
                    preconditionFailure("Failed to URL-escape string: \(value)")
                }
            }
            let queryString = join("&", queryItems)
            URL = NSURL(string: "\(path)?\(queryString)")
        }

        if let URL = URL {
            return URL
        } else {
            preconditionFailure("Failed to create valid URL with path: \(path) and parameters: \(parameters)")
        }
    }

}
