//
//  TimelineView.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/5/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import UIKit

// A timeline for Features that the user can scrub through.

final class TimelineView: UIView {

    let scrollView = UIScrollView(frame: CGRectZero)

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureSubviews()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        configureSubviews()
    }

    func prepareWithFeatures(features: [Feature]) {
        // TODO: How will I use the data to configure this view?
    }

    // MARK: Helpers

    private func configureSubviews() {
        scrollView.frame = self.bounds
        scrollView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        addSubview(scrollView)
    }

}
