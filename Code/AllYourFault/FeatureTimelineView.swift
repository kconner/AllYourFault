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

final class FeatureTimelineView: RoundedCornerView, UIScrollViewDelegate {

    static let standardHeight: CGFloat = 64.0

    private static let pointsPerAnimationSecond: CGFloat = 120.0

    private let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())

    weak var featureTimelineViewDelegate: FeatureTimelineViewDelegate?

    lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        // IMPROVE: This doesn't update when the system locale changes, but I think I can live with that for a sample app.
        formatter.dateFormat = NSDateFormatter.dateFormatFromTemplate("M/d", options: 0, locale: NSLocale.currentLocale())
        return formatter
    }()

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
        collectionView.frame = self.bounds
        collectionView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        collectionView.backgroundColor = Colors.backgroundColor
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
        dividerView.backgroundColor = Colors.orangeColor
        dividerView.userInteractionEnabled = false
        addSubview(dividerView)
    }

    func prepareWithAnimatingFeatures(animatingFeatures: [AnimatingFeature], animationDuration: NSTimeInterval, firstDate: NSDate) {
        // Divide features into segments by day.
        var days: [FeatureTimelineDay] = []

        let calendar = NSCalendar.currentCalendar()
        let oneDayComponents = NSDateComponents()
        oneDayComponents.day = 1

        // Get parameters for the first day in the timeline.
        var dayDateComponents = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: firstDate)
        let firstDayStartDate: NSDate! = calendar.dateFromComponents(dayDateComponents)
        // When during the first day does the overall animation begin?
        let animationTimeOffset = firstDate.timeIntervalSinceDate(firstDayStartDate) * FeatureMapViewModel.animationTimePerRealTime

        var dayStartDate = firstDayStartDate
        var dayEndDate: NSDate! = calendar.dateByAddingComponents(oneDayComponents, toDate: dayStartDate, options: nil)
        var dayStartIndex = 0
        var dayAnimationStartTime = -animationTimeOffset

        let saveDayWithEndIndex: Int -> Void = { dayEndIndex in
            // Save the day's view model.
            let dayFeatures = animatingFeatures[dayStartIndex..<dayEndIndex]
            let dateString = self.dateFormatter.stringFromDate(dayStartDate)
            let animationDuration = dayEndDate.timeIntervalSinceDate(dayStartDate) * FeatureMapViewModel.animationTimePerRealTime
            days.append(FeatureTimelineDay(animatingFeatures: dayFeatures,
                dateString: dateString,
                animationStartTime: dayAnimationStartTime,
                animationDuration: animationDuration))

            // Advance parameters to the next day.
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

        // Add an empty day, so we can have a terminating vertical line.
        // Set the duration so the cell will be just one point wide.
        let onePointDuration = 1.0 / NSTimeInterval(FeatureTimelineView.pointsPerAnimationSecond)
        days.append(FeatureTimelineDay(animatingFeatures: animatingFeatures[dayStartIndex..<dayStartIndex],
            dateString: "",
            animationStartTime: dayAnimationStartTime,
            animationDuration: onePointDuration))

        self.days = days
        animationPointOffsetInFirstDay = round(CGFloat(animationTimeOffset) * FeatureTimelineView.pointsPerAnimationSecond)

        collectionView.reloadData()
        currentAnimationTime = 0.0
    }

    func stopDecelerating() {
        if collectionView.decelerating {
            // Interrupt the deceleration animation by starting a new animation to the offset where we already are.
            collectionView.setContentOffset(collectionView.contentOffset, animated: true)
        }
    }

    // MARK: UIView

    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(0.0, FeatureTimelineView.standardHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Inset half the width at the beginning and end of the scroll view, so we can always scroll cells across the center line.
        collectionView.contentInset = UIEdgeInsetsMake(0.0, bounds.midX, 0.0, bounds.midX - 1.0)
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
            return CGSizeMake(round(CGFloat(day.animationDuration) * FeatureTimelineView.pointsPerAnimationSecond), FeatureTimelineView.standardHeight)
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
