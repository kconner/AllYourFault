//
//  FeatureMapViewController.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/3/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import UIKit
import MapKit

// The app's main view.

// Moving the map affects the data state.
// The data state affects view configuration and animation availability.
// When animations are available, the user can play and pause or scrub on the timeline.

final class FeatureMapViewController: UIViewController {

    private enum DataState {
        case Empty
        case Loading(NSURLSessionTask)
        case Populated(FeatureMapViewModel)

        var currentUpdateTask: NSURLSessionTask? {
            switch self {
            case .Loading(let task):
                return task
            default:
                return nil
            }
        }
        
        var viewModel: FeatureMapViewModel? {
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
    @IBOutlet var timelineView: FeatureTimelineView!

    private var lastMapRegion: MKCoordinateRegion!

    private var dataState = DataState.Empty {
        didSet {
            resetViewsForDataState()
        }
    }

    private var animationTime: NSTimeInterval = 0.0 {
        didSet {
            if animationTime != oldValue {
                moveAnimationToTime(animationTime)
            }
        }
    }

    private var displayLink: CADisplayLink?

    deinit {
        displayLink?.invalidate()
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        lastMapRegion = mapView.region
        mapView.delegate = self

        timelineView.featureTimelineViewDelegate = self

        resetViewsForDataState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Maintain view animation time on rotation.
        timelineView.currentAnimationTime = animationTime
    }

}

// MARK: Data state

extension FeatureMapViewController {

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

                strongSelf.enterStateForAPIResult(result)
            }
        }

        dataState = .Loading(task)
        task.resume()
    }

    private var coordinateRegionForQuery: MKCoordinateRegion {
        // TODO: 100 -> distance from top of timeline view to bottom of map view
        let unobscuredRect = UIEdgeInsetsInsetRect(mapView.bounds, UIEdgeInsetsMake(0.0, 0.0, 100.0, 0.0))
        return mapView.convertRect(unobscuredRect, toRegionFromView: mapView)
    }

    private func enterStateForAPIResult(result: APIResult<[Feature], APIError>) {
        switch result {
        case .Success(let features):
            if 0 < features.unbox.count {
                let viewModel = FeatureMapViewModel(features: features.unbox)
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

    private func resetViewsForDataState() {
        // Tear down views
        mapView.removeAnnotations(mapView.annotations)

        // TODO: Hide loading state view, empty state view

        // Reset animation state
        pauseAnimation()
        animationTime = 0.0

        // Set up views
        switch dataState {
        case .Empty:
            // TODO: Show empty state
            playPauseButton.enabled = false
        case .Loading:
            // TODO: Show loading state
            playPauseButton.enabled = false
        case .Populated(let viewModel):
            // TODO: Set up the timeline view
            timelineView.prepareWithAnimatingFeatures(viewModel.animatingFeatures, animationDuration: viewModel.animationDuration, firstDate: viewModel.firstDate)
            playPauseButton.enabled = true
        }

        if let animationFeatures = dataState.viewModel?.animatingFeatures {
            let features = animationFeatures.map { $0.feature }
            mapView.addAnnotations(features)
        }
    }

}

// MARK: Animation

extension FeatureMapViewController {

    var isAnimationAvailable: Bool {
        return dataState.viewModel != nil
    }

    @IBAction func didTapPlayPauseButton(sender: AnyObject) {
        timelineView.stopDecelerating()

        if let displayLink = displayLink {
            pauseAnimation()
        } else {
            playAnimation()
        }
    }

    private func pauseAnimation() {
        playPauseButton.setImage(UIImage(named: "play"), forState: .Normal)

        invalidateDisplayLink()
    }

    private func playAnimation() {
        playPauseButton.setImage(UIImage(named: "pause"), forState: .Normal)

        invalidateDisplayLink()

        let displayLink = CADisplayLink(target: self, selector: "advanceAnimation:")
        self.displayLink = displayLink
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode) // TODO: Correct run loop mode?
    }

    private func invalidateDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    func advanceAnimation(displayLink: CADisplayLink) {
        animationTime += displayLink.duration

        timelineView.currentAnimationTime = animationTime
    }

    private func moveAnimationToTime(time: NSTimeInterval) {
        if let animationFeatures = dataState.viewModel?.animatingFeatures {
            for animationFeature in animationFeatures {
                if let annotationView = mapView.viewForAnnotation(animationFeature.feature) as? FeatureAnnotationView {
                    annotationView.finalScale = animationFeature.scale
                    annotationView.animationInterpolant = (time - animationFeature.startTime) / animationFeature.duration
                }
            }
        }
    }

}

extension FeatureMapViewController: MKMapViewDelegate {

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
    }

}

extension FeatureMapViewController: FeatureTimelineViewDelegate {

    func featureTimelineView(featureTimelineView: FeatureTimelineView, didScrubToTime time: NSTimeInterval) {
        if isAnimationAvailable {
            pauseAnimation()
            animationTime = time
        }
    }

}
