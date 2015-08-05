//
//  APIRequest.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import Foundation

// A request that can be sent to the web service and that maps JSON response bodies to success or failure values.

struct APIRequest<T> {

    typealias SuccessType = T
    typealias FailureType = APIError
    typealias ResultType = APIResult<SuccessType, FailureType>

    // Using computed properties because structs don't yet support static stored properties:
    var successStatusCodeRange: Range<Int> {
        return 200..<300
    }
    var expectedFailureStatusCodeRange: Range<Int> {
        return 400..<500
    }

    var failureKey: String {
        return "metadata"
    }
    var mapFailureValue: PlistValue -> FailureType? {
        return APIError.mapPlistValue
    }

    let URL: NSURL
    let successKey: String
    let mapSuccessValue: PlistValue -> SuccessType?

    init(URL: NSURL, successKey: String, mapSuccessValue: PlistValue -> T?) {
        self.URL = URL
        self.successKey = successKey
        self.mapSuccessValue = mapSuccessValue
    }

    func sendWithSession(session: NSURLSession, completion: ResultType -> Void) -> NSURLSessionTask {
        let task = session.dataTaskWithRequest(NSURLRequest(URL: URL), completionHandler: { (data, response, error) -> Void in
            // In the shared instance of NSURLSession, this closure is called on a background thread, but I want to let that
            // worker continue quickly. So only make the branch decision here, then do the rest on the appropriate thread.
            if let data = data,
                let HTTPResponse = response as? NSHTTPURLResponse {

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    let result = self.resultWithData(data, HTTPStatusCode: HTTPResponse.statusCode)
                    
                    // Return on the main thread.
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(result)
                    }
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    if let error = error {
                        let message = error.localizedFailureReason ?? "Sorry, we couldn't reach the web service."
                        completion(APIRequest.incompleteRequestResultWithMessage(message))
                    } else {
                        completion(APIRequest.unknownErrorResultWithStatusCode(APIError.unknownErrorStatus))
                    }
                }
            }
        })

        task.resume()

        return task
    }

    // MARK: Helpers

    private func resultWithData(responseBodyData: NSData, HTTPStatusCode: Int) -> ResultType {
        // Parse response body as JSON to plist objects.
        var error: NSError?
        let plistValue: PlistValue = NSJSONSerialization.JSONObjectWithData(responseBodyData, options: nil, error: &error)
        if let error = error {
            return APIRequest.invalidDataResultWithStatusCode(HTTPStatusCode)
        }

        let statusCode = applicationStatusCodeWithPlistValue(plistValue, HTTPStatusCode: HTTPStatusCode)

        // Produce result value, usually by mapping plist objects to native objects.
        switch statusCode {
        case successStatusCodeRange:
            if let dictionary = MapPlist.dictionary(plistValue),
                let successValue = mapSuccessValue(dictionary[successKey]) {
                    
                return APIResult.success(successValue)
            } else {
                // Failed to map the success response data.
                return APIRequest.invalidDataResultWithStatusCode(statusCode)
            }
        case expectedFailureStatusCodeRange:
            if let dictionary = MapPlist.dictionary(plistValue),
                let failureValue = mapFailureValue(dictionary[failureKey]) {

                return APIResult.failure(failureValue)
            } else {
                // Failed to map the error, so we don't know what the error was.
                return APIRequest.unknownErrorResultWithStatusCode(statusCode)
            }
        default:
            // Unexpected failure
            return APIRequest.unknownErrorResultWithStatusCode(statusCode)
        }
    }

    private func applicationStatusCodeWithPlistValue(plistValue: PlistValue, HTTPStatusCode: Int) -> Int {
        // Surprise! The API sends a 200 HTTP status code, but in a failure case, its status field says 4xx.
        // We get to hack around that.
        if successStatusCodeRange ~= HTTPStatusCode {
            if let dictionary = MapPlist.dictionary(plistValue),
                let metadata = MapPlist.dictionary(dictionary["metadata"]),
                let status = MapPlist.int(metadata["status"]) {

                // The HTTP status code was in the 2xx range, and we were able to parse the (sigh) application status code.
                // So, use the application status code.
                return status
            }
        }

        return HTTPStatusCode
    }

    private static func incompleteRequestResultWithMessage(message: String) -> ResultType {
        return APIResult.failure(APIError(statusCode: APIError.incompleteRequestStatus,
            title: "Connection error",
            message: message))
    }

    private static func invalidDataResultWithStatusCode(statusCode: Int) -> ResultType {
        return APIResult.failure(APIError(statusCode: statusCode,
            title: "Invalid data",
            message: "We couldn't understand the data returned from the web service."))
    }
    
    private static func unknownErrorResultWithStatusCode(statusCode: Int) -> ResultType {
        return APIResult.failure(APIError(statusCode: statusCode,
            title: "Unknown error",
            message: "Sorry, something went wrong."))
    }

}
