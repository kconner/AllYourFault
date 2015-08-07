//
//  AnimatingFeature.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/6/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import UIKit

// A feature with its animation scheduling parameters.

struct AnimatingFeature {

    // Largest expected magnitude of a recorded earthquake.
    static let magnitudeMax: Double = 10.0

    // Duration of a ripple animation at max magnitude.
    static let animationDurationMax: NSTimeInterval = 2.0

    // Final scale of a ripple animation at max magnitude.
    static let animationScaleMax: CGFloat = 20.0

    let feature: Feature
    let startTime: NSTimeInterval
    let duration: NSTimeInterval
    let scale: CGFloat

    init(feature: Feature, startTime: NSTimeInterval) {
        self.feature = feature
        self.startTime = startTime

        let severity = feature.magnitude / AnimatingFeature.magnitudeMax
        duration = severity * AnimatingFeature.animationDurationMax
        scale = CGFloat(severity) * AnimatingFeature.animationScaleMax
    }

}
