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
    static let magnitudeMax: Double = 9.0

    // Duration of a ripple animation at max magnitude.
    static let animationDurationMax: NSTimeInterval = 3.0

    // Final scale of a ripple animation at max magnitude.
    static let animationScaleMax: CGFloat = 50.0

    let feature: Feature
    let startTime: NSTimeInterval
    let severity: Double

    var duration: NSTimeInterval {
        return severity * AnimatingFeature.animationDurationMax
    }

    var scale: CGFloat {
        return CGFloat(severity) * AnimatingFeature.animationScaleMax
    }

    init(feature: Feature, startTime: NSTimeInterval) {
        self.feature = feature
        self.startTime = startTime

        // Rather than representing a powers-of-ten scale, just express some exaggeration with magnitude.
        let base = 1.25
        severity = pow(base, feature.magnitude) / pow(base, AnimatingFeature.magnitudeMax)
    }

}
