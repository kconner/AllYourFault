//
//  FeatureTimelineDay.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/6/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import Foundation

// A day's worth of Feature data on the timeline.

struct FeatureTimelineDay {

    let animatingFeatures: ArraySlice<AnimatingFeature>
    let dateString: String
    let animationStartTime: TimeInterval
    let animationDuration: TimeInterval

}
