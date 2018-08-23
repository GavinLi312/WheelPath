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

struct PublicToilets{
    
}
class MapViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var MapView: MKMapView!
    let manager = CLLocationManager()
    var Option : String?
    var annotationList : [CustomPointAnnotation] = []
    
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

    override func viewWillAppear(_ animated: Bool) {
        switch Option {
        case functionList[0]:
            
            MapView.removeAnnotations(MapView.annotations)
            putToiletsOnMap()

            
        case functionList[1]:
            print(functions.object(forKey: Option as! NSString)?.count)
        default:
            print("nil")
        }
        
        MapView.addAnnotations(self.annotationList)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showAnnotations(_ Option:String) {
        
    }
    
    // show user's location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let region = MKCoordinateRegion(center: myLocation, span: span)
        MapView.setRegion(region, animated: true)
    }
    
    //change all the toilets into annotations
    func putToiletsOnMap() {
        let publicToilets = functions.object(forKey: functionList[0] as! NSString) as! [PublicToilet]
        for toilet in publicToilets{
            var annotation = CustomPointAnnotation()
            annotation.title = toilet.id!
            annotation.subtitle = toilet.desc!
            annotation.coordinate = CLLocationCoordinate2DMake(toilet.latitude!, toilet.longitude!)
            if toilet.disableFlag == "Yes"{
                annotation.imageName = "toliet-40"
            }else{
                annotation.imageName = "toliet-no-40"
            }
            self.annotationList.append(annotation)
        }
        }
    
    // add anotation in the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let btn = UIButton(type: .infoDark) as UIButton
        
        if !(annotation is MKPointAnnotation){
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "facility")
        if annotationView == nil{
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "facility")
            annotationView!.canShowCallout = true
        }
        else {
            annotationView!.annotation = annotation
        }
        
        let image = annotation as! CustomPointAnnotation
        annotationView?.rightCalloutAccessoryView = btn
        annotationView!.image = UIImage(named: image.imageName)

        return annotationView
    }


    }

