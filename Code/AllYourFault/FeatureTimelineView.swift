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

    func featureTimelineView(_ featureTimelineView: FeatureTimelineView, didScrubToTime time: TimeInterval)

}

final class FeatureTimelineView: RoundedCornerView {

    static let standardHeight: CGFloat = 64.0

    fileprivate static let pointsPerAnimationSecond: CGFloat = 120.0

    private let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())

    weak var featureTimelineViewDelegate: FeatureTimelineViewDelegate?

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // IMPROVE: This doesn't update when the system locale changes, but I think I can live with that for a sample app.
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "M/d", options: 0, locale: Locale.current)
        return formatter
    }()

    var currentAnimationTime: TimeInterval {
        get {
            return TimeInterval((collectionView.contentOffset.x - animationPointOffset) / FeatureTimelineView.pointsPerAnimationSecond)
        }
        set {
            collectionView.contentOffset = CGPoint(x: animationPointOffset + round(CGFloat(newValue) * FeatureTimelineView.pointsPerAnimationSecond), y: 0.0)
        }
    }

    fileprivate var days: [FeatureTimelineDay] = []

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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }

    private func configureView() {
        collectionView.frame = self.bounds
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = Colors.backgroundColor
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(FeatureTimelineDayCell.self, forCellWithReuseIdentifier: FeatureTimelineDayCell.reuseIdentifier)

        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.sectionInset = .zero

        addSubview(collectionView)

        let dividerView = UIView(frame: CGRect(x: self.bounds.midX, y: 0.0, width: 1.0, height: self.bounds.height))
        dividerView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleHeight]
        dividerView.backgroundColor = Colors.orangeColor
        dividerView.isUserInteractionEnabled = false
        addSubview(dividerView)
    }

    func prepare(animatingFeatures: [AnimatingFeature], animationDuration: TimeInterval, firstDate: Date) {
        // Divide features into segments by day.
        var days: [FeatureTimelineDay] = []

        let calendar = Calendar.current
        var oneDayComponents = DateComponents()
        oneDayComponents.day = 1

        // Get parameters for the first day in the timeline.
        let dayDateComponents = calendar.dateComponents([.year, .month, .day], from: firstDate)
        let firstDayStartDate = calendar.date(from: dayDateComponents)!
        // When during the first day does the overall animation begin?
        let animationTimeOffset = firstDate.timeIntervalSince(firstDayStartDate) * FeatureMapViewModel.animationTimePerRealTime

        var dayStartDate = firstDayStartDate
        var dayEndDate = calendar.date(byAdding: oneDayComponents, to: dayStartDate)!
        var dayStartIndex = 0
        var dayAnimationStartTime = -animationTimeOffset

        let saveDayWithEndIndex: (Int) -> Void = { dayEndIndex in
            // Save the day's view model.
            let dayFeatures = animatingFeatures[dayStartIndex..<dayEndIndex]
            let dateString = self.dateFormatter.string(from: dayStartDate)
            let animationDuration = dayEndDate.timeIntervalSince(dayStartDate) * FeatureMapViewModel.animationTimePerRealTime
            days.append(FeatureTimelineDay(animatingFeatures: dayFeatures,
                dateString: dateString,
                animationStartTime: dayAnimationStartTime,
                animationDuration: animationDuration))

            // Advance parameters to the next day.
            dayStartDate = dayEndDate
            dayEndDate = calendar.date(byAdding: oneDayComponents, to: dayStartDate)!
            dayStartIndex = dayEndIndex
            dayAnimationStartTime += animationDuration
        }

        // Features are ordered by date, and we are configured for the first day.
        // Find the end index for each day by walking through all the features.
        for (index, animatingFeature) in animatingFeatures.enumerated() {
            while animatingFeature.feature.date.compare(dayEndDate) != .orderedAscending {
                saveDayWithEndIndex(index)
            }
        }

        // Save the last day too.
        saveDayWithEndIndex(animatingFeatures.count)

        // Add an empty day, so we can have a terminating vertical line.
        // Set the duration so the cell will be just one point wide.
        let onePointDuration = 1.0 / TimeInterval(FeatureTimelineView.pointsPerAnimationSecond)
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
        if collectionView.isDecelerating {
            // Interrupt the deceleration animation by starting a new animation to the offset where we already are.
            collectionView.setContentOffset(collectionView.contentOffset, animated: true)
        }
    }

    // MARK: UIView

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 0.0, height: FeatureTimelineView.standardHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Inset half the width at the beginning and end of the scroll view, so we can always scroll cells across the center line.
        collectionView.contentInset = UIEdgeInsetsMake(0.0, bounds.midX, 0.0, bounds.midX - 1.0)
    }

}

extension FeatureTimelineView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private func day(at indexPath: IndexPath) -> FeatureTimelineDay? {
        guard days.indices ~= indexPath.row else {
            return nil
        }

        return days[indexPath.row]
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureTimelineDayCell.reuseIdentifier, for: indexPath) 

        if let dayCell = cell as? FeatureTimelineDayCell,
            let day = day(at: indexPath)
        {
            dayCell.featureTimelineDay = day
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let day = day(at: indexPath) else {
            return .zero
        }

        return CGSize(width: round(CGFloat(day.animationDuration) * FeatureTimelineView.pointsPerAnimationSecond), height: FeatureTimelineView.standardHeight)
    }

}

extension FeatureTimelineView: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Only report scrolling done by the user.
        if scrollView.isTracking || scrollView.isDecelerating {
            featureTimelineViewDelegate?.featureTimelineView(self, didScrubToTime: currentAnimationTime)
        }
    }

}
