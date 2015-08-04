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

    @IBOutlet var mapView: MKMapView!

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        // Test JSON mapping.
        var error: NSError?
        if let path = NSBundle.mainBundle().pathForResource("features", ofType: "json"),
            let data = NSData(contentsOfFile: path, options: nil, error: &error) {

            let plistValue: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error)
            assert(error == nil, "Should not have failed to parse JSON to plist objects.")

            NSLog("starting to map")
            let startDate = NSDate()

            let m = MapPlist.self
            if let dictionary = m.dictionary(plistValue),
                let features = m.array(Feature.mapPlistValue)(dictionary["features"]) {

                // Break here and debug to verify our mapping succeeded.
                NSLog("%d features mapped", features.count)
            }

            NSLog("finished mapping, %fs elapsed", NSDate().timeIntervalSinceDate(startDate))
        } else {
            NSLog("Failed to open file.")
        }
    }

}
