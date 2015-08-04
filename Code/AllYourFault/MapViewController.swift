//
//  MapViewController.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/3/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import UIKit
import MapKit

final class MapViewController: UIViewController {

    static let testSubviewTag = 101

    @IBOutlet var mapView: MKMapView!

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        // Test with 10,000 annotations since the web service has a bit under 9,000 seismic events
        for x in 0..<100 {
            for y in 0..<100 {
                let coordinate = CLLocationCoordinate2D(latitude: 35.0 + 0.01 * Double(y), longitude: -85.0 + 0.01 * Double(x))
                let hidden = (x + y) % 111 != 0 // 90 annotation views visible at a time, even though the annotations are always there.
                mapView.addAnnotation(Earthquake(coordinate: coordinate, hidden: hidden))
            }
        }
    }

    // MARK: Helpers

    @IBAction func didTapTestButton(sender: UIButton) {
        // Make all the subviews of visible annotations animate to see how it performs.
        UIView.animateWithDuration(0.25) {
            for annotationObject in self.mapView.annotationsInMapRect(self.mapView.visibleMapRect) {
                if let earthquake = annotationObject as? Earthquake,
                    let subview = self.mapView.viewForAnnotation(earthquake).viewWithTag(MapViewController.testSubviewTag) {

                    subview.frame = CGRectOffset(subview.frame, 10.0, 10.0)
                }
            }
        }
    }

}

extension MapViewController: MKMapViewDelegate {

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseIdentifier = "Pin"

        let annotationView: MKAnnotationView
        if let existingView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) {
            annotationView = existingView
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)

            // Add subviews to all the visible annotations. They should exceed the bounds of the annotation views
            // so we can see if MapKit does anything special with annotation view clipping.
            let testSubview = UIImageView(image: UIImage(named: "earthquake"))
            testSubview.tag = MapViewController.testSubviewTag
            testSubview.alpha = 0.5 // To test animation performance with alpha blending
            annotationView.addSubview(testSubview)
        }

        configureView(annotationView, forAnnotation: annotation)

        return annotationView
    }

    private func configureView(annotationView: MKAnnotationView, forAnnotation annotation: MKAnnotation) {
        // In order to see how many annotations we can actually show at a given time, hide some fraction of them.
        if let earthquake = annotation as? Earthquake {
            annotationView.hidden = earthquake.hidden
        }
    }

}
