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

    private var lastRegion: MKCoordinateRegion!

    private var lastUpdateTask: NSURLSessionTask?

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        lastRegion = mapView.region
        mapView.delegate = self
    }

    // MARK: Helpers

    private var coordinateRegionForQuery: MKCoordinateRegion {
        // TODO: 100 -> distance from top of timeline view to bottom of map view
        let unobscuredRect = UIEdgeInsetsInsetRect(mapView.bounds, UIEdgeInsetsMake(0.0, 0.0, 0.0, 100.0))
        return mapView.convertRect(unobscuredRect, toRegionFromView: mapView)
    }

    private func updateData() {
        // Allow only one update task to run at a time.
        lastUpdateTask?.cancel()

        let request = APIEndpoints.highestMagnitudeEarthquakesRequestWithCoordinateRegion(coordinateRegionForQuery, limit: 100)
        var task: NSURLSessionTask! = nil
        task = request.taskWithSession(NSURLSession.sharedSession()) { [weak self] result -> Void in
            // I'd like to have a mechanism to cancel this task after the response is received but before result preparation ends.
            // Mapping 100 earthquakes to native objects usually takes 0.18s on iPhone 6, and that's a wide enough window to get unwanted results.
            // For now I'm using the task identifier to ensure we only use the response for the most recently sent request.
            if let strongSelf = self,
                let task = task
                where task.taskIdentifier == strongSelf.lastUpdateTask?.taskIdentifier {

                strongSelf.lastUpdateTask = nil

                switch result {
                case .Success(let box):
                    NSLog("success: \(box.unbox.count) items")
                case .Failure(let box):
                    NSLog("failure: \(box.unbox.title)\n\(box.unbox.message)")
                }
            }
        }

        lastUpdateTask = task
        task.resume()
    }

    // Test a request for data.
    @IBAction func didTapTestButton(sender: AnyObject) {
        updateData()
    }

}

extension MapViewController: MKMapViewDelegate {

    private func coordinateRegionsAreEqual(region1: MKCoordinateRegion, _ region2: MKCoordinateRegion) -> Bool {
        return region1.center.latitude == region2.center.latitude
            && region1.center.longitude == region2.center.longitude
            && region1.span.latitudeDelta == region2.span.latitudeDelta
            && region1.span.longitudeDelta == region2.span.longitudeDelta
    }

    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        let region = mapView.region
        if !coordinateRegionsAreEqual(lastRegion, region) {
            lastRegion = region
            updateData()
        }
    }

}
