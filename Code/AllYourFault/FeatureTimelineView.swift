//
//  FeatureTimelineView.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/5/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import UIKit

// A timeline for Features that the user can scrub through.

protocol FeatureTimelineViewDelegate: class {

    func featureTimelineView(featureTimelineView: FeatureTimelineView, didScrubToTime time: NSTimeInterval)

}

final class FeatureTimelineView: UIView, UIScrollViewDelegate {

    private static let pointsPerAnimationSecond: CGFloat = 60.0
    private static let standardHeight: CGFloat = 64.0

    let scrollView = UIScrollView(frame: CGRectZero)

    weak var featureTimelineViewDelegate: FeatureTimelineViewDelegate?

    var currentAnimationTime: NSTimeInterval {
        get {
            return NSTimeInterval(scrollView.contentOffset.x / FeatureTimelineView.pointsPerAnimationSecond)
        }
        set {
            scrollView.contentOffset = CGPointMake(round(CGFloat(newValue) * FeatureTimelineView.pointsPerAnimationSecond), 0.0)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureSubviews()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        configureSubviews()
    }

    func prepareWithAnimatingFeatures(animationFeatures: [AnimatingFeature], animationDuration: NSTimeInterval, startDate: NSDate) {
        // TODO: How will I use the data to configure this view?
    }

    // MARK: UIView

    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(0.0, FeatureTimelineView.standardHeight)
    }

    // MARK: Helpers

    private func configureSubviews() {
        scrollView.frame = self.bounds
        scrollView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        scrollView.delegate = self
        // TODO: do this in prepare, and give it the right width
        scrollView.contentSize = CGSizeMake(1000.0, FeatureTimelineView.standardHeight)
        addSubview(scrollView)
    }

}

extension FeatureTimelineView: UIScrollViewDelegate {

    func scrollViewDidScroll(scrollView: UIScrollView) {
        // Only report scrolling done by the user.
        if scrollView.tracking || scrollView.decelerating {
            featureTimelineViewDelegate?.featureTimelineView(self, didScrubToTime: currentAnimationTime)
        }
    }

}
