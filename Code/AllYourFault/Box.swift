//
//  Box.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/4/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

// Utility class for working around Swift 1.2's requirement of constant size for enum values.

final class Box<T> {

    let unbox: T

    init(_ value: T) {
        unbox = value
    }

}
