//
//  FeatureTimelineDay.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/6/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

// A day's worth of Feature data on the timeline.

import Foundation

struct FeatureTimelineDay {

    let animatingFeatures: ArraySlice<AnimatingFeature>

    let dateString: String

    let animationStartTime: NSTimeInterval

    // Days can have different lengths, e.g. daylight savings.
    let animationDuration: NSTimeInterval

}
