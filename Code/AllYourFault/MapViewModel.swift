//
//  MapViewModel.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/5/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import Foundation

// View model for the MapViewController's populated state.
// Keeps track of feature objects and animation parameters.

struct MapViewModel {

    typealias AnimationFeature = (feature: Feature, startTime: NSTimeInterval, duration: NSTimeInterval)

    // Animate 365 days of history per second.
    static let animationTimePerRealTime: NSTimeInterval = 1.0 / (60 * 60 * 24 * 365)

    // Longest possible duration of a feature's ripple animation.
    static let featureAnimationDurationMax: NSTimeInterval = 2.0

    // Duration of the entire map's animation over all features.
    let animationDuration: NSTimeInterval

    // Features collected with their animation scheduling parameters.
    let animationFeatures: [AnimationFeature]

    init(features: [Feature]) {
        precondition(0 < features.count, "There should be at least one Feature.")

        let orderedFeatures = features.sorted { (feature1: Feature, feature2: Feature) -> Bool in
            return feature1.date.compare(feature2.date) == .OrderedAscending
        }

        let firstDate = orderedFeatures.first!.date
        let lastDate = orderedFeatures.last!.date
        let realDateInterval = lastDate.timeIntervalSinceDate(firstDate)

        // Time to animate from the beginning of the first feature animation to after the end of the last one.
        animationDuration = realDateInterval * MapViewModel.animationTimePerRealTime + MapViewModel.featureAnimationDurationMax

        animationFeatures = orderedFeatures.map { feature in
            let startTime: NSTimeInterval = feature.date.timeIntervalSinceDate(firstDate) * MapViewModel.animationTimePerRealTime
            // TODO: Interpolate duration using magnitude
            let duration: NSTimeInterval = MapViewModel.featureAnimationDurationMax
            return (feature: feature, startTime: startTime, duration: duration)
        }

    }

}
