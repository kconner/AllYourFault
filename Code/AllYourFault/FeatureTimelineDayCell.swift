//
//  FeatureTimelineDayCell.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/6/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import UIKit

// A day of time on the FeatureTimelineView.

final class FeatureTimelineDayCell: UICollectionViewCell {

    static let reuseIdentifier = "FeatureTimelineDayCell"

    // TODO: Pick particular colors and organize them in a class
    private static let blackColor = UIColor(white: 0.0, alpha: 0.4)
    private static let textAttributes: [NSObject: AnyObject] = [
        NSForegroundColorAttributeName: blackColor,
        NSFontAttributeName: UIFont.systemFontOfSize(13.0)
    ]

    var featureTimelineDay: FeatureTimelineDay? {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }

    private func configureView() {
        // TODO: Pick particular colors and organize them in a class
        backgroundColor = UIColor.whiteColor()
    }

    // MARK: UIView

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()

        // Draw hash line at the left edge.
        FeatureTimelineDayCell.blackColor.setFill()
        CGContextFillRect(context, CGRectMake(0.0, 0.0, 0.5, rect.height))

        if let featureTimelineDay = featureTimelineDay {
            // Draw day text next to the hash line, on the bottom.
            featureTimelineDay.dateString.drawAtPoint(CGPointMake(3.0, rect.height - 15.0), withAttributes: FeatureTimelineDayCell.textAttributes)
            
            // Draw dots for each feature.
            // TODO: Vertical lines instead?

            // With a radius of one point and rounding to whole points, dots won't be cut off on cell boundaries.
            // Then, the day begins halfway through the cell's first point, at the right edge of the hash.
            let dotRect = CGRectMake(-2.0, -2.0, 4.0, 4.0)
            for animatingFeature in featureTimelineDay.animatingFeatures {
                let xOffset = rect.width * CGFloat((animatingFeature.startTime - featureTimelineDay.animationStartTime) / featureTimelineDay.animationDuration)
                let yOffset = rect.height * (1.0 - CGFloat(animatingFeature.feature.magnitude / AnimatingFeature.magnitudeMax))
                let dotFrame = dotRect.rectByOffsetting(dx: xOffset, dy: yOffset)
                
                // TODO: Pick particular colors and organize them in a class
                UIColor.redColor().setFill()
                CGContextFillEllipseInRect(context, dotFrame)
            }
        }
    }

}
