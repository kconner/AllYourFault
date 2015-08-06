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

    let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())

    weak var featureTimelineViewDelegate: FeatureTimelineViewDelegate?

    var currentAnimationTime: NSTimeInterval {
        get {
            return NSTimeInterval(collectionView.contentOffset.x / FeatureTimelineView.pointsPerAnimationSecond)
        }
        set {
            collectionView.contentOffset = CGPointMake(round(CGFloat(newValue) * FeatureTimelineView.pointsPerAnimationSecond), 0.0)
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

        // collectionView.contentSize = CGSizeMake(1000.0, FeatureTimelineView.standardHeight)
    }

    // MARK: UIView

    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(0.0, FeatureTimelineView.standardHeight)
    }

    // MARK: Helpers

    private func configureSubviews() {
        collectionView.frame = self.bounds
        collectionView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerNib(UINib(nibName: "FeatureTimelineYearCell", bundle: nil), forCellWithReuseIdentifier: FeatureTimelineYearCell.reuseIdentifier)

        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = .Horizontal
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.sectionInset = UIEdgeInsetsZero

        addSubview(collectionView)
    }

}

extension FeatureTimelineView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // TODO: Based on the animation date ranges, decide the year range.
        return 100
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(FeatureTimelineYearCell.reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell

        if let yearCell = cell as? FeatureTimelineYearCell {
            // TODO: Configure with segment, not arbitrarily
            yearCell.year = indexPath.row + 1933
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        // TODO: Width per segment should depend on the actual duration of that year.
        return CGSizeMake(FeatureTimelineView.pointsPerAnimationSecond, FeatureTimelineView.standardHeight)
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
