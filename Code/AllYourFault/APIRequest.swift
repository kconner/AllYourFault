//
//  APIRequest.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import Foundation

// A request that can be sent to the API.

struct APIRequest<T> {

    typealias SuccessType = T
    typealias FailureType = APIError
    typealias ResultType = APIResult<SuccessType, FailureType>

    var failureKey: String {
        return "metadata"
    }
    var mapFailureValue: AnyObject? -> FailureType? {
        return APIError.mapPlistValue
    }

    let URL: NSURL
    let parameters: [String: String]
    let successKey: String
    let mapSuccessValue: AnyObject? -> SuccessType?

    init(URL: NSURL, parameters: [String: String] = [:], successKey: String, mapSuccessValue: AnyObject? -> T?) {
        self.URL = URL
        self.parameters = parameters
        self.successKey = successKey
        self.mapSuccessValue = mapSuccessValue
    }

    func send(completion: ResultType -> Void) {
        // TODO: Use NSURLSession to get data for the URL and parameters
        // If the response status is in 200..<300, map success with features
        // If the response is in 400..<500, map error with metadata
        // Otherwise produce a generic "something went wrong error.

        // Mock the above.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.mockResponse(completion)
        }
    }

    // MARK: Helpers

    private func mockResponse(completion: ResultType -> Void) {
        var error: NSError?
        
        let status: Int
        var responseData: NSData?
        switch arc4random_uniform(3) {
        case 0:
            if let path = NSBundle.mainBundle().pathForResource("features", ofType: "json"),
                let data = NSData(contentsOfFile: path, options: nil, error: &error) {
                    
                responseData = data
            }
            status = 200
        case 1:
            if let path = NSBundle.mainBundle().pathForResource("error", ofType: "json"),
                let data = NSData(contentsOfFile: path, options: nil, error: &error) {
                    
                responseData = data
            }
            status = 400
        default:
            status = 500
        }
        
        let plistValue: AnyObject?
        // TODO: responseData should not be nil when it comes from the web service
        if let data = responseData {
            plistValue = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error)
            
            if let error = error {
                completion(invalidDataResultWithStatus(status))
            }
        } else {
            plistValue = nil
        }
        
        switch status {
        case 200..<300:
            if let dictionary = MapPlist.dictionary(plistValue),
                let successValue = mapSuccessValue(dictionary[successKey]) {
                    
                completion(APIResult.success(successValue))
            } else {
                completion(invalidDataResultWithStatus(status))
            }
        case 400..<500:
            if let dictionary = MapPlist.dictionary(plistValue),
                let failureValue = mapFailureValue(dictionary[failureKey]) {
                    
                completion(APIResult.failure(failureValue))
            } else {
                completion(unknownErrorResultWithStatus(status))
            }
        default:
            completion(unknownErrorResultWithStatus(status))
        }
    }

    private func invalidDataResultWithStatus(status: Int) -> ResultType {
        return APIResult.failure(APIError(status: status, title: "Invalid data", message: "We couldn't understand the data returned from the web service."))
    }
    
    private func unknownErrorResultWithStatus(status: Int) -> ResultType {
        return APIResult.failure(APIError(status: status, title: "Unknown error", message: "Sorry, something went wrong."))
    }

}
