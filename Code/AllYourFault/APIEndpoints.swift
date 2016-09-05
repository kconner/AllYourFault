//
//  APIEndpoints.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import Foundation
import MapKit

// Factory methods for common endpoints.
// These would be in an extension on the APIRequest class if it didn't take type parameters.

final class APIEndpoints {

    class func highestMagnitudeEarthquakesRequestWithCoordinateRegion(region: MKCoordinateRegion, limit: Int) -> APIRequest<[Feature]> {
        let halfSpanLatitude = region.span.latitudeDelta / 2.0
        let halfSpanLongitude = region.span.longitudeDelta / 2.0

        let url = URLWithPath("http://ehp2-earthquake.wr.usgs.gov/fdsnws/event/1/query",
            parameters: ["format": "geojson",
                "jsonerror": "true",
                "eventtype": "earthquake",
                // This can wrap around the International Date Line,
                // but that's recommended behavior in this API.
                "minlatitude": "\(max(-90.0, region.center.latitude - halfSpanLatitude))",
                "maxlatitude": "\(min(90.0, region.center.latitude + halfSpanLatitude))",
                "minlongitude": "\(region.center.longitude - halfSpanLongitude)",
                "maxlongitude": "\(region.center.longitude + halfSpanLongitude)",
                "limit": String(limit),
                "orderby": "magnitude"])

        return APIRequest<[Feature]>(URL: url,
            successKey: "features",
            mapSuccessValue: MapPlist.array(false, mapItem: Feature.mapPlistValue))
    }

    // MARK: Helpers

    private class func URLWithPath(path: String, parameters: [String: String] = [:]) -> NSURL {
        let URL: NSURL?
        if parameters.count == 0 {
            URL = NSURL(string: path)
        } else {
            let queryItems = parameters.map { (key, value) -> String in
                if let escapedValue = value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet()) {
                    return "\(key)=\(escapedValue)"
                } else {
                    preconditionFailure("Failed to URL-escape string: \(value)")
                }
            }
            let queryString = queryItems.joinWithSeparator("&")
            URL = NSURL(string: "\(path)?\(queryString)")
        }

        if let URL = URL {
            return URL
        } else {
            preconditionFailure("Failed to create valid URL with path: \(path) and parameters: \(parameters)")
        }
    }

}
