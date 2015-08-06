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
// Chain of effects: mapView.region, lastMapRegion -> dataState -> mapView.annotations

final class MapViewController: UIViewController {

    private enum DataState {
        case Empty
        case Loading(NSURLSessionTask)
        case Populated([Feature])
        
        var currentUpdateTask: NSURLSessionTask? {
            switch self {
            case .Loading(let task):
                return task
            default:
                return nil
            }
        }
        
        var features: [Feature] {
            switch self {
            case .Populated(let features):
                return features
            default:
                return []
            }
        }
    }

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var playPauseButton: UIButton!

    private var lastMapRegion: MKCoordinateRegion!

    private var dataState = DataState.Empty {
        didSet {
            replaceAnnotationsWithFeatures()
        }
    }

    private var isPlaying = false {
        didSet {
            if isPlaying {
                playPauseButton.setImage(UIImage(named: "pause"), forState: .Normal)
            } else {
                playPauseButton.setImage(UIImage(named: "play"), forState: .Normal)
            }
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        lastMapRegion = mapView.region
        mapView.delegate = self
    }

    // MARK: Helpers

    private var coordinateRegionForQuery: MKCoordinateRegion {
        // TODO: 100 -> distance from top of timeline view to bottom of map view
        let unobscuredRect = UIEdgeInsetsInsetRect(mapView.bounds, UIEdgeInsetsMake(0.0, 0.0, 100.0, 0.0))
        return mapView.convertRect(unobscuredRect, toRegionFromView: mapView)
    }

    private func loadDataForMapRegion() {
        // Allow only one update task to run at a time.
        dataState.currentUpdateTask?.cancel()

        let request = APIEndpoints.highestMagnitudeEarthquakesRequestWithCoordinateRegion(coordinateRegionForQuery, limit: 100)
        var task: NSURLSessionTask! = nil
        task = request.taskWithSession(NSURLSession.sharedSession()) { [weak self] result -> Void in
            // I'd like to have a mechanism to cancel this task after the response is received but before result preparation ends.
            // Mapping 100 earthquakes to native objects usually takes 0.18s on iPhone 6, and that's a wide enough window to get unwanted results.
            // For now I'm using the task identifier to ensure we only use the response for the most recently sent request.
            if let strongSelf = self,
                let task = task
                where task.taskIdentifier == strongSelf.dataState.currentUpdateTask?.taskIdentifier {

                strongSelf.enterStateForResult(result)
            }
        }

        dataState = .Loading(task)
        task.resume()
    }

    private func enterStateForResult(result: APIResult<[Feature], APIError>) {
        switch result {
        case .Success(let features):
            dataState = .Populated(features.unbox)
        case .Failure(let error):
            dataState = .Empty
            let alertController = UIAlertController(title: error.unbox.title, message: error.unbox.message, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
            presentViewController(alertController, animated: true, completion: nil)
        }
    }

    private func replaceAnnotationsWithFeatures() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(dataState.features)
    }

    @IBAction func didTapPlayPauseButton(sender: AnyObject) {
        isPlaying = !isPlaying
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

        // We can get duplicate calls to this method with no change. Only load new data if the region changed meaningfully.
        if !coordinateRegionsAreEqual(lastMapRegion, region) {
            lastMapRegion = region
            loadDataForMapRegion()
        }
    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseIdentifier = "FeatureAnnotation"

        if let feature = annotation as? Feature {
            let annotationView: FeatureAnnotationView
            if let existingAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as? FeatureAnnotationView {
                annotationView = existingAnnotationView
            } else {
                annotationView = FeatureAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            }

            configureFeatureAnnotationView(annotationView, withFeature: feature)
            return annotationView
        } else {
            preconditionFailure("Only Features should be used for annotations.")
        }
    }

    private func configureFeatureAnnotationView(annotationView: FeatureAnnotationView, withFeature feature: Feature) {
        // TODO
    }

}
