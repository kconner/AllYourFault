//
//  MapViewController.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/3/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import UIKit
import MapKit

// The app's main view.

final class MapViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!

    let request = APIEndpoints.dummyRequest()

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: Helpers

    // Test a request for data.
    @IBAction func didTapTestButton(sender: AnyObject) {
        NSLog("sending request")
        request.send() { result -> Void in
            switch result {
            case .Success(let box):
                NSLog("success: \(box.unbox.count) items")
            case .Failure(let box):
                NSLog("failure: \(box.unbox.title)\n\(box.unbox.message)")
            }
        }
    }

}
