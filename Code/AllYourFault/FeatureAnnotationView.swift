//
//  FeatureAnnotationView.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/5/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import MapKit

final class FeatureAnnotationView: MKAnnotationView {

    // init(frame:) is called by init(annotation:reuseIdentifier:).
    // We must implement both, so may as well do setup here.
    override init(frame: CGRect) {
        super.init(frame: frame)

        image = UIImage(named: "annotation")
    }

    override init!(annotation: MKAnnotation!, reuseIdentifier: String!) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }

    required init(coder aDecoder: NSCoder) {
        preconditionFailure("Initializing FeatureAnnotationView with an NSCoder is not supported.")
    }

}
