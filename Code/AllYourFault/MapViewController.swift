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
        if let path = NSBundle.mainBundle().pathForResource("error", ofType: "json"),
            let data = NSData(contentsOfFile: path, options: nil, error: &error) {

            let plistValue: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error)
            assert(error == nil, "Should not have failed to parse JSON to plist objects.")

            let m = MapPlist.self
            if let dictionary = m.dictionary(plistValue),
                let error = APIError.mapPlistValue(dictionary["metadata"]) {

                // Break here and debug to verify our mapping succeeded.
                NSLog("mapped error object")
            }
        } else {
            NSLog("Failed to open file.")
        }
    }

}
