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
        case Populated(MapViewModel)
        
        var currentUpdateTask: NSURLSessionTask? {
            switch self {
            case .Loading(let task):
                return task
            default:
                return nil
            }
        }
        
        var viewModel: MapViewModel? {
            switch self {
            case .Populated(let viewModel):
                return viewModel
            default:
                return nil
            }
        }
    }

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var playPauseButton: UIButton!

    private var lastMapRegion: MKCoordinateRegion!

    private var dataState = DataState.Empty {
        didSet {
            resetAnnotationsAndAnimation()
        }
    }

    private var animationTime: NSTimeInterval = 0.0 {
        didSet {
            if animationTime != oldValue {
                moveAnimationToTime(animationTime)
            }
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
            if 0 < features.unbox.count {
                let viewModel = MapViewModel(features: features.unbox)
                dataState = .Populated(viewModel)
            } else {
                dataState = .Empty
            }
        case .Failure(let error):
            dataState = .Empty
            presentAPIError(error.unbox)
        }
    }

    private func presentAPIError(error: APIError) {
        let alertController = UIAlertController(title: error.title, message: error.message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }

    private func resetAnnotationsAndAnimation() {
        mapView.removeAnnotations(mapView.annotations)
        animationTime = 0.0
        if let animationFeatures = dataState.viewModel?.animationFeatures {
            let features = animationFeatures.map { $0.feature }
            mapView.addAnnotations(features)
        }
    }

    @IBAction func didTapPlayPauseButton(sender: AnyObject) {
        isPlaying = !isPlaying

        // TODO: Instead of manually advancing time, animate with a CADisplayLink.
        animationTime += 0.1
    }

    private func moveAnimationToTime(time: NSTimeInterval) {
        if let animationFeatures = dataState.viewModel?.animationFeatures {
            for animationFeature in animationFeatures {
                if let annotationView = mapView.viewForAnnotation(animationFeature.feature) as? FeatureAnnotationView {
                    annotationView.animationInterpolant = (time - animationFeature.startTime) / animationFeature.duration
                }
            }
        }
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

    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        // TODO: Seek to this annotation's point in the timeline.
        (view as! FeatureAnnotationView).animationInterpolant += 0.1
    }

}
