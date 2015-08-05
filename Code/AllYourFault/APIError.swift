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
    static let incompleteRequestStatus = -1 // Request failed in NSURLSession as opposed to at the server.
    static let unknownErrorStatus = -2 // Something Else Went Wrong™

    let statusCode: Int // status
    let title: String // title
    let message: String // error

    static func mapPlistValue(value: PlistValue) -> APIError? {
        let m = MapPlist.self
        if let dictionary = m.dictionary(value),
            let statusCode = m.int(dictionary["status"]),
            let title = m.string(dictionary["title"]),
            let message = m.string(dictionary["error"]) {

            return APIError(statusCode: statusCode, title: title, message: message)
        } else {
            return nil
        }
    }

}
