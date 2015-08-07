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

    private static let pointsPerAnimationSecond: CGFloat = 120.0
    private static let standardHeight: CGFloat = 64.0

    private let maskLayer = CAShapeLayer()
    private let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())

    weak var featureTimelineViewDelegate: FeatureTimelineViewDelegate?

    var currentAnimationTime: NSTimeInterval {
        get {
            return NSTimeInterval((collectionView.contentOffset.x - animationPointOffset) / FeatureTimelineView.pointsPerAnimationSecond)
        }
        set {
            collectionView.contentOffset = CGPointMake(animationPointOffset + round(CGFloat(newValue) * FeatureTimelineView.pointsPerAnimationSecond), 0.0)
        }
    }

    private var days: [FeatureTimelineDay] = []

    // The whole animation begins sometime during the first day, not at the beginning of the first day.
    private var animationPointOffsetInFirstDay: CGFloat = 0.0
    // A given feature should animate when its dot reaches the center line.
    private var animationPointOffset: CGFloat {
        return animationPointOffsetInFirstDay - bounds.midX
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
        self.layer.mask = maskLayer

        collectionView.frame = self.bounds
        collectionView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        // TODO: Specific colors
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(FeatureTimelineDayCell.self, forCellWithReuseIdentifier: FeatureTimelineDayCell.reuseIdentifier)

        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = .Horizontal
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.sectionInset = UIEdgeInsetsZero

        addSubview(collectionView)

        let dividerView = UIView(frame: CGRectMake(self.bounds.midX, 0.0, 1.0, self.bounds.height))
        dividerView.autoresizingMask = .FlexibleLeftMargin | .FlexibleRightMargin | .FlexibleHeight
        // TODO: Specific colors
        dividerView.backgroundColor = UIColor.redColor()
        dividerView.userInteractionEnabled = false
        addSubview(dividerView)
    }

    func prepareWithAnimatingFeatures(animatingFeatures: [AnimatingFeature], animationDuration: NSTimeInterval, firstDate: NSDate) {
        // Divide features into segments by day.
        var days: [FeatureTimelineDay] = []

        // TODO: Test with non-gregorian calendars.
        let calendar = NSCalendar.currentCalendar()
        let oneDayComponents = NSDateComponents()
        oneDayComponents.day = 1

        // Get parameters for the first day in the timeline.
        var dayDateComponents = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: firstDate)
        let firstDayStartDate: NSDate! = calendar.dateFromComponents(dayDateComponents)
        // When during the first day does the overall animation begin?
        let animationTimeOffset = firstDate.timeIntervalSinceDate(firstDayStartDate) * FeatureMapViewModel.animationTimePerRealTime

        var day = dayDateComponents.day
        var dayStartDate = firstDayStartDate
        var dayEndDate: NSDate! = calendar.dateByAddingComponents(oneDayComponents, toDate: dayStartDate, options: nil)
        var dayStartIndex = 0
        var dayAnimationStartTime = -animationTimeOffset

        let saveDayWithEndIndex: Int -> Void = { dayEndIndex in
            // Save the day's view model.
            let dayFeatures = animatingFeatures[dayStartIndex..<dayEndIndex]
            let dateString = String(day) // TODO: Use a date formatter instead
            let animationDuration = dayEndDate.timeIntervalSinceDate(dayStartDate) * FeatureMapViewModel.animationTimePerRealTime
            days.append(FeatureTimelineDay(animatingFeatures: dayFeatures,
                dateString: dateString,
                animationStartTime: dayAnimationStartTime,
                animationDuration: animationDuration))

            // Advance parameters to the next day.
            ++day
            dayStartDate = dayEndDate
            dayEndDate = calendar.dateByAddingComponents(oneDayComponents, toDate: dayStartDate, options: nil)
            dayStartIndex = dayEndIndex
            dayAnimationStartTime += animationDuration
        }

        // Features are ordered by date, and we are configured for the first day.
        // Find the end index for each day by walking through all the features.
        for (index, animatingFeature) in enumerate(animatingFeatures) {
            while animatingFeature.feature.date.compare(dayEndDate) != .OrderedAscending {
                saveDayWithEndIndex(index)
            }
        }

        // Save the last day too.
        saveDayWithEndIndex(animatingFeatures.count)

        self.days = days
        animationPointOffsetInFirstDay = round(CGFloat(animationTimeOffset) * FeatureTimelineView.pointsPerAnimationSecond)

        collectionView.reloadData()
        currentAnimationTime = 0.0
    }

    // MARK: UIView

    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(0.0, FeatureTimelineView.standardHeight)
    }

    // MARK: CALayerDelegate

    override func layoutSublayersOfLayer(layer: CALayer!) {
        super.layoutSublayersOfLayer(layer)

        if layer == self.layer {
            maskLayer.frame = layer.bounds
            maskLayer.path = UIBezierPath(roundedRect: maskLayer.bounds, cornerRadius: 10.0).CGPath
        }
    }

}

extension FeatureTimelineView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private func dayAtIndexPath(indexPath: NSIndexPath) -> FeatureTimelineDay? {
        if indices(days) ~= indexPath.row {
            return days[indexPath.row]
        } else {
            return nil
        }
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(FeatureTimelineDayCell.reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell

        if let dayCell = cell as? FeatureTimelineDayCell,
            let day = dayAtIndexPath(indexPath) {
            dayCell.featureTimelineDay = day
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if let day = dayAtIndexPath(indexPath) {
            return CGSizeMake(round(CGFloat(day.animationDuration) * FeatureTimelineView.pointsPerAnimationSecond),
                FeatureTimelineView.standardHeight)
        } else {
            return CGSizeZero
        }
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
