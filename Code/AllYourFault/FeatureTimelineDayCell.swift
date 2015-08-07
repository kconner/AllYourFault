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

    private static let textAttributes: [NSObject: AnyObject] = [
        NSForegroundColorAttributeName: Colors.textColor,
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
        backgroundColor = Colors.backgroundColor
    }

    // MARK: UIView

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()

        // Draw hash line at the left edge.
        Colors.textColor.setFill()
        CGContextFillRect(context, CGRectMake(0.0, 0.0, 0.5, rect.height))

        if let featureTimelineDay = featureTimelineDay {
            // Draw day text next to the hash line, on the bottom.
            featureTimelineDay.dateString.drawAtPoint(CGPointMake(3.0, rect.height - 15.0), withAttributes: FeatureTimelineDayCell.textAttributes)
            
            // Draw dots for each feature.
            let dotRadius: CGFloat = 1.75
            let dotRect = CGRectMake(-dotRadius, -dotRadius, dotRadius * 2.0, dotRadius * 2.0)
            Colors.orangeColor.setFill()
            for animatingFeature in featureTimelineDay.animatingFeatures {
                let xPosition = rect.width * CGFloat((animatingFeature.startTime - featureTimelineDay.animationStartTime) / featureTimelineDay.animationDuration)
                // If a dot would end up being cut off by the cell boundary, scoot it in a pixel or two.
                let xOffset = max(dotRadius, min(rect.width - dotRadius, xPosition))
                let yOffset = rect.height * (1.0 - CGFloat(animatingFeature.feature.magnitude / AnimatingFeature.magnitudeMax))
                let dotFrame = dotRect.rectByOffsetting(dx: xOffset, dy: yOffset)
                
                CGContextFillEllipseInRect(context, dotFrame)
            }
        }
    }

}
