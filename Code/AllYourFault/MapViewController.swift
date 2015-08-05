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

    // TODO: Probably don't need reusable references to these; just illustrating architecture for a minute.
    let request = APIEndpoints.allEarthquakesRequest()
    let session = NSURLSession.sharedSession()

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: Helpers

    // Test a request for data.
    @IBAction func didTapTestButton(sender: AnyObject) {
        NSLog("sending request")
        request.sendWithSession(session) { result -> Void in
            switch result {
            case .Success(let box):
                NSLog("success: \(box.unbox.count) items")
            case .Failure(let box):
                NSLog("failure: \(box.unbox.title)\n\(box.unbox.message)")
            }
        }
    }

}
