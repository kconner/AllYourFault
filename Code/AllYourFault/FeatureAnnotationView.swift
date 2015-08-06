//
//  FeatureAnnotationView.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/5/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import MapKit

// Represents a Feature on the map.

final class FeatureAnnotationView: MKAnnotationView {

    private let rippleLayer = CALayer()

    var animationTime: NSTimeInterval = 0.0 {
        didSet {
            if animationTime != oldValue {
                animateToTime(animationTime, fromTime: oldValue)
            }
        }
    }

    // init(frame:) is called by init(annotation:reuseIdentifier:).
    // We must implement both, so may as well do setup here.
    override init(frame: CGRect) {
        super.init(frame: frame)

        image = UIImage(named: "annotation")
        let imageSize = image.size

        // TODO: custom ripple image
        if let rippleImage = UIImage(named: "annotation") {
            rippleLayer.contents = rippleImage.CGImage
            rippleLayer.bounds = CGRect(origin: CGPointZero, size: rippleImage.size)
            rippleLayer.position = CGPointMake(imageSize.width / 2.0, imageSize.height / 2.0)
            rippleLayer.anchorPoint = CGPointMake(0.5, 0.5)
        } else {
            assertionFailure("Ripple image did not exist.")
        }

        rippleLayer.opacity = 0.0
        rippleLayer.transform = CATransform3DMakeScale(0.0, 0.0, 0.0)
        layer.addSublayer(rippleLayer)
    }

    override init!(annotation: MKAnnotation!, reuseIdentifier: String!) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }

    required init(coder aDecoder: NSCoder) {
        preconditionFailure("Initializing FeatureAnnotationView with an NSCoder is not supported.")
    }

    // MARK: Helpers

    private func animateToTime(time: NSTimeInterval, fromTime: NSTimeInterval) {
        let maxScale: CGFloat = 10.0
        let maxOpacity: Float = 1.0

        let rippleScale: CGFloat
        let rippleOpacity: Float

        if time <= 0.0 || 1.0 <= time {
            if fromTime <= 0.0 || 1.0 <= fromTime {
                // There is no significant work to do since neither timestamp is within the animation.
                return
            }

            // We are outside the animation. Hide the layer completely.
            rippleScale = 0.0
            rippleOpacity = 0.0
        } else {
            rippleScale = maxScale * CGFloat(time)

            // Fade in over the first fifth, then fade out over the remaining time.
            if time < 0.2 {
                rippleOpacity = maxOpacity * 5.0 * Float(time)
            } else {
                rippleOpacity = maxOpacity * 5.0 / 4.0 * (1.0 - Float(time))
            }
        }

        rippleLayer.opacity = rippleOpacity
        rippleLayer.transform = CATransform3DMakeScale(rippleScale, rippleScale, rippleScale)
    }
}
