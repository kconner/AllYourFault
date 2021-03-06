//
//  APIError.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

// A web service error object produced by some failure in the web service, the request, or the connection.

struct APIError {

    // statusCode is usually an HTTP status code, but can also be:
    static let incompleteRequestStatus = -1 // Request failed in URLSession as opposed to at the server.
    static let unknownErrorStatus = -2 // Something Else Went Wrong™

    let statusCode: Int // status
    let title: String // title
    let message: String // error

    static func mapPlistValue(_ value: PlistValue) -> APIError? {
        guard let dictionary = MapPlist.dictionary(value),
            let statusCode = MapPlist.int(dictionary["status"] as PlistValue),
            let title = MapPlist.string(dictionary["title"] as PlistValue),
            let message = MapPlist.string(dictionary["error"] as PlistValue) else
        {
            return nil
        }

        return APIError(statusCode: statusCode, title: title, message: message)
    }

}
