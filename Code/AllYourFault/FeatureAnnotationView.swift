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

    var finalScale: CGFloat = 0.0

    // Animation runs from 0.0 to 1.0.
    var animationInterpolant: NSTimeInterval = 0.0 {
        didSet {
            if animationInterpolant != oldValue {
                moveAnimationToInterpolant(animationInterpolant, fromInterpolant: oldValue)
            }
        }
    }

    // init(frame:) is called by init(annotation:reuseIdentifier:).
    // We must implement both, so may as well do setup here.
    override init(frame: CGRect) {
        super.init(frame: frame)

        image = UIImage(named: "annotation")
        let imageSize = image?.size ?? .zero

        if let rippleImage = UIImage(named: "ripple") {
            rippleLayer.contents = rippleImage.CGImage
            rippleLayer.bounds = CGRect(origin: CGPointZero, size: rippleImage.size)
            rippleLayer.position = CGPointMake(imageSize.width / 2.0, imageSize.height / 2.0)
            rippleLayer.anchorPoint = CGPointMake(0.5, 0.5)
        } else {
            assertionFailure("Ripple image did not exist.")
        }

        rippleLayer.opacity = 0.0
        rippleLayer.transform = CATransform3DMakeScale(0.0, 0.0, 0.0)
        // Disable implicit animations.
        rippleLayer.actions = ["opacity": NSNull(), "transform": NSNull()]
        layer.addSublayer(rippleLayer)
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        preconditionFailure("Initializing FeatureAnnotationView with an NSCoder is not supported.")
    }

    // MARK: Helpers

    private func moveAnimationToInterpolant(interpolant: NSTimeInterval, fromInterpolant: NSTimeInterval) {
        let maxOpacity: Float = 1.0

        let rippleScale: CGFloat
        let rippleOpacity: Float

        if interpolant <= 0.0 || 1.0 <= interpolant {
            if fromInterpolant <= 0.0 || 1.0 <= fromInterpolant {
                // There is no significant work to do since neither timestamp is within the animation.
                return
            }

            // We are outside the animation. Hide the layer completely.
            rippleScale = 0.0
            rippleOpacity = 0.0
        } else {
            rippleScale = finalScale * CGFloat(interpolant)

            // Fade in over the first fifth, then fade out over the remaining time.
            if interpolant < 0.2 {
                rippleOpacity = maxOpacity * 5.0 * Float(interpolant)
            } else if interpolant < 0.5 {
                rippleOpacity = 1.0
            } else {
                // Quadratic ease-in from 0.5 to 1.0
                let squareTerm = 2.0 * (Float(interpolant) - 0.5)
                rippleOpacity = maxOpacity * (1.0 - squareTerm * squareTerm)
            }
        }

        rippleLayer.opacity = rippleOpacity
        rippleLayer.transform = CATransform3DMakeScale(rippleScale, rippleScale, rippleScale)
    }

    // MARK: MKAnnotationView

    override func prepareForReuse() {
        super.prepareForReuse()

        animationInterpolant = 0.0
    }

}
