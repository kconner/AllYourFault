//
//  MapViewController.swift
//  AllYourFault
//
//  Created by Kevin Conner on 8/3/15.
//  Copyright (c) 2015 Kevin Conner. All rights reserved.
//

import UIKit
import MapKit
import SceneKit

final class MapViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var sceneView: SCNView!

    private let mapPlane = SCNPlane(width: 320, height: 480) // Size can be updated later.

    private var regionDidChangeCompletion: (() -> Void)?
    private var didFinishRenderingMapCompletion: (() -> Void)?

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        // TODO: Just for testing
        sceneView.allowsCameraControl = true

        // TODO: Since scene view will show and hide, have a method to reconfigure it, animated or not. Maybe a view state setter.
        sceneView.hidden = true
        sceneView.backgroundColor = UIColor.blackColor()
        sceneView.scene = createScene()
    }

    // MARK: Helpers

    private func createScene() -> SCNScene {
        let scene = SCNScene()

        let mapPlaneNode = SCNNode(geometry: mapPlane)
        scene.rootNode.addChildNode(mapPlaneNode)

        // TODO: nodes earthquake epicenter and force spheres

        return scene
    }

    @IBAction func didTapTestButton(sender: UIButton) {
        positionCameraBeforeShowingSceneView()
    }

    private func positionCameraBeforeShowingSceneView() {
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.0, longitude: -95.0),
            span: MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 10.0))

        // TODO: Would be safer to have a state enum instead so we can't get collisions.
        regionDidChangeCompletion = showSceneView

        mapView.setRegion(region, animated: true)
    }

    private func showSceneView() {
        // First, sample an image of the map.
        NSLog("Preparing scene view")

        let bounds = mapView.bounds
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        mapView.drawViewHierarchyInRect(bounds, afterScreenUpdates: true)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        mapPlane.width = CGRectGetWidth(bounds) / 1.5
        mapPlane.height = CGRectGetHeight(bounds) / 1.5
        mapPlane.firstMaterial?.diffuse.contents = snapshotImage
        mapPlane.firstMaterial?.doubleSided = true

        sceneView.hidden = false
    }

}

extension MapViewController: MKMapViewDelegate {

    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        NSLog("Region changed")
        if let completion = regionDidChangeCompletion {
            regionDidChangeCompletion = nil
            // TODO: This is weird. Definitely want that state enum. Do these always happen in this order? Should we just wait for each to happen once?
            didFinishRenderingMapCompletion = completion
        }
    }

    // TODO: If this doesn't get called, i bet its counterpart won't either. So really we need to take the snapshot when the map
    // is not in a still-rendering state after the region has changed.
//    func mapViewWillStartRenderingMap(mapView: MKMapView!) {
//    }

    func mapViewDidFinishRenderingMap(mapView: MKMapView!, fullyRendered: Bool) {
        NSLog("Finished rendering")
        if let completion = didFinishRenderingMapCompletion {
            didFinishRenderingMapCompletion = nil
            completion()
        }
    }

}
