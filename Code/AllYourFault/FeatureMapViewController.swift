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
        case empty(String?)
        case loading(URLSessionTask)
        case populated(FeatureMapViewModel)
        case populatedAndLoading(URLSessionTask, FeatureMapViewModel)

        var currentUpdateTask: URLSessionTask? {
            switch self {
            case .loading(let task):
                return task
            case .populatedAndLoading(let task, _):
                return task
            default:
                return nil
            }
        }
        
        var viewModel: FeatureMapViewModel? {
            switch self {
            case .populated(let viewModel):
                return viewModel
            case .populatedAndLoading(_, let viewModel):
                return viewModel
            default:
                return nil
            }
        }
    }

    fileprivate static let messageViewVerticalMargin: CGFloat = 8.0
    fileprivate static let messageViewOutsetWhenHidden: CGFloat = 16.0
    fileprivate static let controlsVerticalMargin: CGFloat = 16.0
    fileprivate static let controlsOutsetWhenHidden: CGFloat = 32.0

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var messageView: UIView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var messageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var timelineView: FeatureTimelineView!
    @IBOutlet var timelineViewBottomConstraint: NSLayoutConstraint!

    fileprivate var lastMapRegion: MKCoordinateRegion!

    fileprivate var dataState: DataState = .empty(nil) {
        didSet {
            resetViewsForDataState(animated: true)
        }
    }

    fileprivate var animationTime: TimeInterval = 0.0 {
        didSet {
            if animationTime != oldValue {
                moveAnimation(to: animationTime)
            }
        }
    }

    fileprivate var displayLink: CADisplayLink?
    fileprivate var lastDisplayLinkTimestamp: TimeInterval?

    deinit {
        displayLink?.invalidate()
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        lastMapRegion = mapView.region
        mapView.delegate = self

        messageView.backgroundColor = Colors.backgroundColor
        messageLabel.backgroundColor = Colors.backgroundColor
        messageLabel.textColor = Colors.textColor

        timelineView.featureTimelineViewDelegate = self

        resetViewsForDataState(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Maintain view animation time on rotation.
        timelineView.currentAnimationTime = animationTime
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

extension FeatureMapViewController {

    // MARK: Data state

    fileprivate func loadDataForMapRegion() {
        // Allow only one update task to run at a time.
        dataState.currentUpdateTask?.cancel()

        let request = APIEndpoints.requestForHighestMagnitudeEarthquakes(in: coordinateRegionForQuery, limit: 100)
        var task: URLSessionTask! = nil
        task = request.task(in: URLSession.shared) { [weak self] result -> Void in
            // I'd like to have a mechanism to cancel this task after the response is received but before result preparation ends.
            // Mapping 100 earthquakes to native objects usually takes 0.18s on iPhone 6, and that's a wide enough window to get unwanted results.
            // For now I'm using the task identifier to ensure we only use the response for the most recently sent request.
            if let strongSelf = self,
                let task = task
                , task.taskIdentifier == strongSelf.dataState.currentUpdateTask?.taskIdentifier {

                strongSelf.enterState(for: result)
            }
        }

        switch dataState {
        case .populated(let viewModel):
            dataState = .populatedAndLoading(task, viewModel)
        case .populatedAndLoading(_, let viewModel):
            dataState = .populatedAndLoading(task, viewModel)
        case .empty, .loading:
            dataState = .loading(task)
        }

        task.resume()
    }

    private var coordinateRegionForQuery: MKCoordinateRegion {
        let insets = UIEdgeInsetsMake(0.0, 0.0, FeatureTimelineView.standardHeight + FeatureMapViewController.controlsVerticalMargin, 0.0)
        let unobscuredRect = UIEdgeInsetsInsetRect(mapView.bounds, insets)
        return mapView.convert(unobscuredRect, toRegionFrom: mapView)
    }

    private func enterState(for result: APIResult<[Feature], APIError>) {
        switch result {
        case .Success(let features):
            if 0 < features.count {
                let viewModel = FeatureMapViewModel(features: features)
                dataState = .populated(viewModel)
            } else {
                dataState = .empty("We didn't find any recent earthquakes here.")
            }
        case .Failure(let error):
            dataState = .empty("\(error.title): \(error.message)")
        }
    }

    fileprivate func resetViewsForDataState(animated: Bool) {
        let message: String?
        let showControls: Bool
        let resetFeatureAnimation: Bool

        switch dataState {
        case .empty(let emptyMessage):
            message = emptyMessage
            showControls = false
            resetFeatureAnimation = true
        case .loading:
            message = "Loading…"
            showControls = false
            resetFeatureAnimation = true
        case .populated(let viewModel):
            message = nil
            showControls = true
            resetFeatureAnimation = true
            timelineView.prepare(animatingFeatures: viewModel.animatingFeatures, animationDuration: viewModel.animationDuration, firstDate: viewModel.firstDate)
        case .populatedAndLoading:
            message = "Loading…"
            showControls = true
            resetFeatureAnimation = false
        }

        if resetFeatureAnimation {
            // Tear down annotations
            mapView.removeAnnotations(mapView.annotations)

            if dataState.viewModel != nil {
                // Reset animation state
                pauseAnimation()
                animationTime = 0.0
                
                // Set up annotations, if any
                if let animationFeatures = dataState.viewModel?.animatingFeatures {
                    let features = animationFeatures.map { $0.feature }
                    mapView.addAnnotations(features)
                }
            }
        }

        configureOverlays(message: message, showingControls: showControls, animated: animated)
    }

    private func configureOverlays(message: String?, showingControls showControls: Bool, animated: Bool) {
        // Show or hide the message view.
        let adjustViews: () -> Void = {
            if let message = message {
                self.messageLabel.text = message
                self.messageViewTopConstraint.constant = FeatureMapViewController.messageViewVerticalMargin
                self.messageView.alpha = 1.0
            } else {
                self.messageViewTopConstraint.constant = FeatureMapViewController.messageViewVerticalMargin - FeatureMapViewController.messageViewOutsetWhenHidden
                self.messageView.alpha = 0.0
            }

            if showControls {
                self.timelineViewBottomConstraint.constant = FeatureMapViewController.controlsVerticalMargin
                self.playPauseButton.alpha = 1.0
                self.timelineView.alpha = 1.0
            } else {
                self.timelineViewBottomConstraint.constant = FeatureMapViewController.controlsVerticalMargin - FeatureMapViewController.controlsOutsetWhenHidden
                self.playPauseButton.alpha = 0.0
                self.timelineView.alpha = 0.0
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .beginFromCurrentState, animations: {
                adjustViews()
                self.view.layoutIfNeeded()
            }, completion: nil)
        } else {
            adjustViews()
        }
    }

}

extension FeatureMapViewController {

    // MARK: Feature Animation

    var isAnimationAvailable: Bool {
        return dataState.viewModel != nil
    }

    @IBAction func didTapPlayPauseButton(_ sender: AnyObject) {
        timelineView.stopDecelerating()

        if displayLink != nil {
            pauseAnimation()
        } else {
            playAnimation()
        }
    }

    fileprivate func pauseAnimation() {
        playPauseButton.setImage(UIImage(named: "play"), for: UIControlState())

        invalidateDisplayLink()
    }

    private func playAnimation() {
        playPauseButton.setImage(UIImage(named: "pause"), for: UIControlState())

        invalidateDisplayLink()

        // If we are at the end of the animation, go to the beginning. Otherwise continue from where we are.
        if let animationDuration = dataState.viewModel?.animationDuration
            , animationDuration <= animationTime {

            animationTime = 0.0
        }

        let displayLink = CADisplayLink(target: self, selector: #selector(advanceAnimation(_:)))
        self.displayLink = displayLink
        // .commonModes: Also update during map deceleration animation.
        displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
    }

    private func invalidateDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        lastDisplayLinkTimestamp = nil
    }

    private dynamic func advanceAnimation(_ displayLink: CADisplayLink) {
        if let lastDisplayLinkTimestamp = lastDisplayLinkTimestamp {
            animationTime += displayLink.timestamp - lastDisplayLinkTimestamp

            timelineView.currentAnimationTime = animationTime
        }

        lastDisplayLinkTimestamp = displayLink.timestamp

        // Stop when we reach the total animation duration.
        if let animationDuration = dataState.viewModel?.animationDuration
            , animationDuration <= animationTime {
                
            pauseAnimation()
        }
    }

    fileprivate func moveAnimation(to time: TimeInterval) {
        if let animationFeatures = dataState.viewModel?.animatingFeatures {
            for animationFeature in animationFeatures {
                if let annotationView = mapView.view(for: animationFeature.feature) as? FeatureAnnotationView {
                    annotationView.finalScale = animationFeature.scale
                    annotationView.animationInterpolant = (time - animationFeature.startTime) / animationFeature.duration
                }
            }
        }
    }

}

extension FeatureMapViewController: MKMapViewDelegate {

    private func coordinateRegionsAreEqual(_ region1: MKCoordinateRegion, _ region2: MKCoordinateRegion) -> Bool {
        return region1.center.latitude == region2.center.latitude
            && region1.center.longitude == region2.center.longitude
            && region1.span.latitudeDelta == region2.span.latitudeDelta
            && region1.span.longitudeDelta == region2.span.longitudeDelta
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let region = mapView.region

        // We can get duplicate calls to this method with no change. Only load new data if the region changed meaningfully.
        if !coordinateRegionsAreEqual(lastMapRegion, region) {
            lastMapRegion = region
            loadDataForMapRegion()
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "FeatureAnnotation"

        guard annotation is Feature else {
            preconditionFailure("Only Features should be used for annotations.")
        }

        if let existingAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? FeatureAnnotationView {
            return existingAnnotationView
        } else {
            return FeatureAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        }
    }

}

extension FeatureMapViewController: FeatureTimelineViewDelegate {

    func featureTimelineView(_ featureTimelineView: FeatureTimelineView, didScrubToTime time: TimeInterval) {
        if isAnimationAvailable {
            pauseAnimation()
            animationTime = time
        }
    }

}
