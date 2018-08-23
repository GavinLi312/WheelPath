//
//  MapViewController.swift
//  WheelPath
//
//  Created by Salamender Li on 22/8/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var MapView: MKMapView!
    let manager = CLLocationManager()
    
    // initialize the map
    override func viewDidLoad() {
        super.viewDidLoad()
        MapView.delegate = self
        MapView.showsScale = true
        MapView.showsBuildings = true
        MapView.showsUserLocation = true
        MapView.showsPointsOfInterest = true
        MapView.mapType = MKMapType.standard
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // show user's location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let region = MKCoordinateRegion(center: myLocation, span: span)
        MapView.setRegion(region, animated: true)
    }

}
