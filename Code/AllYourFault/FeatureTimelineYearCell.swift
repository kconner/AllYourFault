//
//  FeatureTimelineYearCell.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/6/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import UIKit

// A year of time on the FeatureTimelineView.

final class FeatureTimelineYearCell: UICollectionViewCell {

    static let reuseIdentifier = "FeatureTimelineYearCell"

    private static let blackColor = UIColor(white: 0.0, alpha: 0.4)
    private static let textAttributes: [NSObject: AnyObject] = [
        NSForegroundColorAttributeName: blackColor,
        NSFontAttributeName: UIFont.systemFontOfSize(13.0)
    ]

    var year = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var featuresInYear: [Feature] = [] {
        didSet {
            if featuresInYear.count != 0 || oldValue.count != 0 {
                setNeedsDisplay()
            }
        }
    }

    private var dateBoundaries: (NSDate, NSTimeInterval) {
        if let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian) {
            let dateComponents = NSDateComponents()
            dateComponents.year = year
            let startDate = calendar.dateFromComponents(dateComponents)

            ++dateComponents.year
            let endDate = calendar.dateFromComponents(dateComponents)

            precondition(startDate != nil && endDate != nil, "Should be able to get Gregorian calendar dates specifying only a year.")

            return (startDate!, endDate!.timeIntervalSinceDate(startDate!))
        } else {
            preconditionFailure("No Gregorian calendar?")
        }
    }

    // MARK: UIView

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()

        // Draw hash line at the left edge
        FeatureTimelineYearCell.blackColor.setFill()
        CGContextFillRect(context, CGRectMake(0.0, 0.0, 0.5, rect.height))

        // Draw year text next to the hash line, on the bottom
        let a = String(year) as NSString
        a.drawAtPoint(CGPointMake(3.0, rect.height - 15.0), withAttributes: FeatureTimelineYearCell.textAttributes)

        // Draw dots for each feature
        let (startDate, duration) = dateBoundaries
        let maxMagnitude = 10.0

        let dotRadius: CGFloat = 1.5
        let dotRect = CGRectMake(-dotRadius, -dotRadius, dotRadius * 2.0, dotRadius * 2.0)
        for feature in featuresInYear {
            let xOffset = rect.width * CGFloat(feature.date.timeIntervalSinceDate(startDate) / duration)
            let yOffset = rect.height * CGFloat(feature.magnitude / maxMagnitude)
            let dotFrame = dotRect.rectByOffsetting(dx: xOffset, dy: yOffset)

            // TODO: Pick particular colors and organize them in a class
            UIColor.redColor().setFill()
            CGContextFillEllipseInRect(context, dotFrame)
        }
    }

}
