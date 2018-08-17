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

    class func requestForHighestMagnitudeEarthquakes(in region: MKCoordinateRegion, limit: Int) -> APIRequest<[Feature]> {
        let halfSpanLatitude = region.span.latitudeDelta / 2.0
        let halfSpanLongitude = region.span.longitudeDelta / 2.0

        let url = self.url(
            path:"https://earthquake.usgs.gov/fdsnws/event/1/query",
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
                "orderby": "magnitude"
            ]
        )

        return APIRequest(
            url: url,
            successKey: "features",
            mapSuccessValue: MapPlist.array(false, mapItem: Feature.mapPlistValue)
        )
    }

    // MARK: Helpers

    private class func url(path: String, parameters: [String: String] = [:]) -> URL {
        guard !parameters.isEmpty else {
            return URL(string: path)!
        }

        let queryItems = parameters.map { (key, value) -> String in
            if let escapedValue = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed) {
                return "\(key)=\(escapedValue)"
            } else {
                preconditionFailure("Failed to URL-escape string: \(value)")
            }
        }
        let queryString = queryItems.joined(separator: "&")
        return URL(string: "\(path)?\(queryString)")!
    }

}
