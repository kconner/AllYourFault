//
//  APIResult.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

// Haskell's Either a b, or LlamaKit's Result. Contains one kind of value or the other.

enum APIResult<A, B> {

    case Success(A)
    case Failure(B)

    static func success(_ value: A) -> APIResult<A, B> {
        return .Success(value)
    }

    static func failure(_ value: B) -> APIResult<A, B> {
        return .Failure(value)
    }

}
