//
//  FeatureMapViewModel.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/5/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import Foundation

// View model for the FeatureMapViewController's populated state.
// Keeps track of feature objects and animation parameters.

struct FeatureMapViewModel {

    // Animate one day of history per second.
    static let animationTimePerRealTime: TimeInterval = 1.0 / (60 * 60 * 24)

    // The entire map's animation over all features.
    let animationDuration: TimeInterval
    let animatingFeatures: [AnimatingFeature]

    // The real date of the first feature.
    let firstDate: Date

    init(features: [Feature]) {
        precondition(0 < features.count, "There should be at least one Feature.")

        let orderedFeatures = features.sorted { (feature1: Feature, feature2: Feature) -> Bool in
            return feature1.date.compare(feature2.date as Date) == .orderedAscending
        }

        let firstDate = orderedFeatures.first!.date
        let lastDate = orderedFeatures.last!.date
        let realDateInterval = lastDate.timeIntervalSince(firstDate as Date)

        // Time to animate from the beginning of the first feature animation to the end of the last one.
        animationDuration = realDateInterval * FeatureMapViewModel.animationTimePerRealTime + 1.5

        animatingFeatures = orderedFeatures.map { feature in
            let startTime: TimeInterval = feature.date.timeIntervalSince(firstDate as Date) * FeatureMapViewModel.animationTimePerRealTime
            return AnimatingFeature(feature: feature, startTime: startTime)
        }

        self.firstDate = firstDate as Date
    }

}
