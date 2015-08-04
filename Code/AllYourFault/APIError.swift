//
//  APIError.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

// A web service error object produced by a bad request.

struct APIError {

    let status: Int // status
    let title: String // title
    let message: String // error

    static func mapPlistValue(value: AnyObject?) -> APIError? {
        let m = MapPlist.self
        if let dictionary = m.dictionary(value),
            let status = m.int(dictionary["status"]),
            let title = m.string(dictionary["title"]),
            let message = m.string(dictionary["error"]) {

            return APIError(status: status, title: title, message: message)
        } else {
            return nil
        }
    }

}
