//
//  APIEndpoints.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import Foundation

// Factory methods for common endpoints.
// These would be in the APIRequest class if it didn't take type parameters.

final class APIEndpoints {

    static func dummyRequest() -> APIRequest<[Feature]> {
        let url = NSURL(string: "http://google.com")!

        return APIRequest<[Feature]>(URL: url,
            successKey: "features",
            mapSuccessValue: MapPlist.array(Feature.mapPlistValue))
    }

}
