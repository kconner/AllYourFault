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
    fileprivate var successStatusCodeRange: CountableRange<Int> {
        return 200..<300
    }
    fileprivate var expectedFailureStatusCodeRange: CountableRange<Int> {
        return 400..<500
    }

    fileprivate var failureKey: String {
        return "metadata"
    }
    fileprivate var mapFailureValue: (PlistValue) -> FailureType? {
        return APIError.mapPlistValue
    }

    fileprivate let url: Foundation.URL
    fileprivate let successKey: String
    fileprivate let mapSuccessValue: (PlistValue) -> SuccessType?

    init(url: Foundation.URL, successKey: String, mapSuccessValue: @escaping (PlistValue) -> SuccessType?) {
        self.url = url
        self.successKey = successKey
        self.mapSuccessValue = mapSuccessValue
    }

    // To perform the request, call .resume() on the NSURLSessionTask produced by this method.
    // You may .cancel() the task to prevent the completion block from being called.
    func taskWithSession(_ session: URLSession, completion: @escaping (ResultType) -> Void) -> URLSessionTask {
        var task: URLSessionTask!
        task = session.dataTask(with: URLRequest(url: url), completionHandler: { (data, response, error) -> Void in
            // In the shared instance of NSURLSession, this closure is called on a background thread, but I want to let that
            // worker continue quickly. So only make the branch decision here, then do the rest on the appropriate thread.
            if let data = data,
                let HTTPResponse = response as? HTTPURLResponse {
                    
                DispatchQueue.global().async {
                    let result = self.resultWithData(data, HTTPStatusCode: HTTPResponse.statusCode)

                    // Return on the main thread.
                    DispatchQueue.main.async {
                        // IMPROVE: I'd like to have a mechanism to cancel this task after the completion block begins but before response preparation ends.
                        completion(result)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    if let error = error {
                        let foundationError = error as NSError
                        if foundationError.domain == NSURLErrorDomain && foundationError.code == NSURLErrorCancelled {
                            // No-op: Don't call completion for a cancelled request.
                        } else {
                            let message = foundationError.localizedDescription
                            completion(APIRequest.incompleteRequestResultWithMessage(message))
                        }
                    } else {
                        completion(APIRequest.unknownErrorResultWithStatusCode(APIError.unknownErrorStatus))
                    }
                }
            }
        })

        return task
    }

    // MARK: Helpers

    fileprivate func resultWithData(_ responseBodyData: Data, HTTPStatusCode: Int) -> ResultType {
        // Parse response body as JSON to plist objects.
        let plistValue: PlistValue
        do {
            plistValue = try JSONSerialization.jsonObject(with: responseBodyData) as PlistValue
        } catch {
            return APIRequest.invalidDataResultWithStatusCode(HTTPStatusCode)
        }
        
        let statusCode = applicationStatusCodeWithPlistValue(plistValue, HTTPStatusCode: HTTPStatusCode)

        // Produce result value, usually by mapping plist objects to native objects.
        switch statusCode {
        case successStatusCodeRange:
            if let dictionary = MapPlist.dictionary(plistValue),
                let successValue = mapSuccessValue(dictionary[successKey] as PlistValue) {
                    
                return APIResult.success(successValue)
            } else {
                // Failed to map the success response data.
                return APIRequest.invalidDataResultWithStatusCode(statusCode)
            }
        case expectedFailureStatusCodeRange:
            if let dictionary = MapPlist.dictionary(plistValue),
                let failureValue = mapFailureValue(dictionary[failureKey] as PlistValue) {

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

    fileprivate func applicationStatusCodeWithPlistValue(_ plistValue: PlistValue, HTTPStatusCode: Int) -> Int {
        // Surprise! The API sends a 200 HTTP status code, but in a failure case, its status field says 4xx.
        // We get to hack around that.
        if successStatusCodeRange ~= HTTPStatusCode {
            if let dictionary = MapPlist.dictionary(plistValue),
                let metadata = MapPlist.dictionary(dictionary["metadata"] as PlistValue),
                let status = MapPlist.int(metadata["status"] as PlistValue) {

                // The HTTP status code was in the 2xx range, and we were able to parse the (sigh) application status code.
                // So, use the application status code.
                return status
            }
        }

        return HTTPStatusCode
    }

    fileprivate static func incompleteRequestResultWithMessage(_ message: String) -> ResultType {
        return APIResult.failure(APIError(statusCode: APIError.incompleteRequestStatus,
            title: "Connection error",
            message: message))
    }

    fileprivate static func invalidDataResultWithStatusCode(_ statusCode: Int) -> ResultType {
        return APIResult.failure(APIError(statusCode: statusCode,
            title: "Invalid data",
            message: "We couldn't understand the data returned from the web service."))
    }
    
    fileprivate static func unknownErrorResultWithStatusCode(_ statusCode: Int) -> ResultType {
        return APIResult.failure(APIError(statusCode: statusCode,
            title: "Unknown error",
            message: "Sorry, something went wrong."))
    }

}
