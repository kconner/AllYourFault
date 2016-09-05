//
//  RoundedCornerView.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/7/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import UIKit

// A view that rounds its corners using a CAShapeLayer mask.

class RoundedCornerView: UIView {

    private let maskLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }

    private func configureView() {
        self.layer.mask = maskLayer
    }

    // MARK: CALayerDelegate

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        if layer == self.layer {
            maskLayer.frame = layer.bounds
            maskLayer.path = UIBezierPath(roundedRect: maskLayer.bounds, cornerRadius: 10.0).cgPath
        }
    }

}
