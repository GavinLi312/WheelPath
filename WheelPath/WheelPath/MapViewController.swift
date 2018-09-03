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
import Firebase

let colors = [UIColor.black,UIColor.blue,UIColor.brown,UIColor.green,UIColor.orange]

var zoomTag = 0
var displayTag = true
class MapViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var MapView: MKMapView!

    
    let manager = CLLocationManager()
    
    var nearby = false
    
    var annotationList : [CustomPointAnnotation] = []
    
    var userLocation : CLLocation = CLLocation()
    
    let defaultdistance = 0.5
    
    var destination : CLLocation?

    
    override func viewDidLoad() {
        zoomTag = 0
        super.viewDidLoad()
        MapView.delegate = self
        MapView.showsScale = true
        MapView.showsBuildings = true
        MapView.showsUserLocation = true
        MapView.showsPointsOfInterest = true
        MapView.mapType = MKMapType.standard
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.locationServicesEnabled(){
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                manager.requestAlwaysAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
            }
        }
     
        
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }

    
    //https://www.hackingwithswift.com/example-code/system/how-to-run-code-after-a-delay-using-asyncafter-and-perform

    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        MapView.removeAnnotations(MapView.annotations)
    }
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//                    self.MapView.addAnnotations(self.getNearbyFacilities())
//        }
        if nearby{
            getNearbyFacilities()
        }
        if self.annotationList.count == 0 && displayTag == true{
            displayErrorMessage(title: "Out of boundry", message: "Sorry, you are not in cbd, that is all we can help")
            displayTag = false
        }else{
            MapView.addAnnotations(self.annotationList)
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
    

        manager.stopUpdatingLocation()
    }
    
    
    // show user's location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        for item in MapView.overlays{
            if item.title == "location circle"{
                MapView.remove(item)
            }
            
        }
        userLocation = location

        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)

        if zoomTag == 0 {
           locateLocation(location: userLocation)
            zoomTag = 1
        }
        
        let rad = CLLocationDistance(500)
        let newCircle = MKCircle(center: CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), radius: rad)
        newCircle.title = "location circle"
        MapView.add(newCircle)
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.destination = CLLocation(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: (self.destination?.coordinate)!, span: span)
        mapView.setRegion(region, animated: true)
        
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
    

    @IBAction func navigationButtonClicked(_ sender: Any) {
        MapView.removeOverlays(MapView.overlays)
        if self.destination == nil{
            displayErrorMessage(title: "No destination", message: "Sorry please select a destination first")
        }else{
            let destinationPlacemark = MKPlacemark(coordinate: (self.destination?.coordinate)!)
            let sourcePlacemark = MKPlacemark(coordinate: (self.userLocation.coordinate))
            let sourceItem = MKMapItem(placemark: sourcePlacemark)
            let destItem = MKMapItem(placemark: destinationPlacemark)
            let directionRequest = MKDirectionsRequest()
            directionRequest.source = sourceItem
            directionRequest.destination = destItem
            directionRequest.transportType = .walking
            directionRequest.requestsAlternateRoutes = true
            
            let directions = MKDirections(request: directionRequest)
            directions.calculate(completionHandler: { (response, error) in
                guard let response = response else{
                    if let error = error{
                        //https://stackoverflow.com/questions/28152526/how-do-i-open-phone-settings-when-a-button-is-clicked
                        let alertView = UIAlertController(title: "No Permission ", message: "No Permission about the Location Service or Internet Connection, Want to change your setting?", preferredStyle: .alert)
                        var settingAction = UIAlertAction(title: "Yes", style: .default, handler: { action in
                            let settingUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                            if let url = settingUrl{
                                UIApplication.shared.openURL(url as URL)
                            }
                        })
                        alertView.addAction(settingAction)
                        
                        alertView.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in
                            print(" no is clicked")
                            
                        }))
                        self.present(alertView, animated: false, completion: nil)
                    }
                    return
                }

                let routes = response.routes
                for item in routes{
                    print(item.distance)
                    for step in item.steps{
                        print(step.instructions)
                    }
                    
                self.MapView.add(item.polyline, level:.aboveRoads )
                let rekt = item.polyline.boundingMapRect
                self.MapView.setRegion(MKCoordinateRegionForMapRect(rekt), animated: true)
                }
                
                // if the distance recommend user not to walk
                if  routes[0].distance > 2500{
                    self.alert(title: "Distance Too Long", message: "It might be too far for you, please try other ways to commute")
                }
                })
        }
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline{
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = colors[Int(arc4random_uniform(UInt32(colors.count)))]
        renderer.lineWidth = 5.0
        return renderer
        }else if overlay is MKCircle{
            let circleView = MKCircleRenderer(overlay: overlay)
            circleView.strokeColor = UIColor.clear
            circleView.fillColor = #colorLiteral(red: 0.6703221798, green: 0.9303917289, blue: 0.7332935929, alpha: 0.3481645976)
            return circleView
        }
        return MKOverlayRenderer()
    }
    
    
    func alert(title: String, message: String)  {
        let alertController = UIAlertController(title:title , message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        alertController.addAction(alertAction)
        self.present(alertController, animated: true, completion: nil )
    }
    
    func locateLocation(location: CLLocation) {
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), span: span)
        MapView.setRegion(region, animated: true)
    }
    
    @IBAction func locateMe(_ sender: Any) {
        locateLocation(location: userLocation)
    }
    
    func getNearbyFacilities(){
        var nearbyAnnotation : [CustomPointAnnotation] = []
        for annotation in self.annotationList {
            let  target = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            let distance = (userLocation.distance(from: target)/1000)
            if distance < defaultdistance{
                nearbyAnnotation.append(annotation)
            }
        }
        self.annotationList = nearbyAnnotation
    }
    
    func displayErrorMessage(title:String, message: String){
        let alertview = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertview.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alertview, animated: true, completion: nil)
    }

    }




