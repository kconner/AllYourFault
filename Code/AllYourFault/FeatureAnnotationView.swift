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
    var animationInterpolant: TimeInterval = 0.0 {
        didSet {
            if animationInterpolant != oldValue {
                moveAnimation(to: animationInterpolant, from: oldValue)
            }
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        image = UIImage(named: "annotation")
        let imageSize = image?.size ?? .zero

        guard let rippleImage = UIImage(named: "ripple") else {
            preconditionFailure("Ripple image did not exist.")
        }

        rippleLayer.contents = rippleImage.cgImage
        rippleLayer.bounds = CGRect(origin: CGPoint.zero, size: rippleImage.size)
        rippleLayer.position = CGPoint(x: imageSize.width / 2.0, y: imageSize.height / 2.0)
        rippleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        rippleLayer.opacity = 0.0
        rippleLayer.transform = CATransform3DMakeScale(0.0, 0.0, 0.0)
        // Disable implicit animations.
        rippleLayer.actions = ["opacity": NSNull(), "transform": NSNull()]
        layer.addSublayer(rippleLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        preconditionFailure("Initializing FeatureAnnotationView with an NSCoder is not supported.")
    }

    // MARK: Helpers

    private func moveAnimation(to newInterpolant: TimeInterval, from oldInterpolant: TimeInterval) {
        let maxOpacity: Float = 1.0

        let rippleScale: CGFloat
        let rippleOpacity: Float

        if newInterpolant <= 0.0 || 1.0 <= newInterpolant {
            if oldInterpolant <= 0.0 || 1.0 <= oldInterpolant {
                // There is no significant work to do since neither timestamp is within the animation.
                return
            }

            // We are outside the animation. Hide the layer completely.
            rippleScale = 0.0
            rippleOpacity = 0.0
        } else {
            rippleScale = finalScale * CGFloat(newInterpolant)

            // Fade in over the first fifth, then fade out over the remaining time.
            if newInterpolant < 0.2 {
                rippleOpacity = maxOpacity * 5.0 * Float(newInterpolant)
            } else if newInterpolant < 0.5 {
                rippleOpacity = 1.0
            } else {
                // Quadratic ease-in from 0.5 to 1.0
                let squareTerm = 2.0 * (Float(newInterpolant) - 0.5)
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
