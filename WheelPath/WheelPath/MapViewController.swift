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
var displaySourceTag = true

let cbdPostcode = ["3141","3004","3002","3000","3006","3053","3005","3008","3051","3052","3010","3050","3054","3031","3003","3207","3032"]
class MapViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var MapView: MKMapView!

    let manager = CLLocationManager()
    
    var nearby = false
    
    var annotationList : [CustomPointAnnotation] = []
    
    var userLocation : CLLocation = CLLocation()
    
    let defaultdistance = 0.5
    
    var destination : CLLocation?
    // if search and nearby are true, the route will be showen
    // startItem and destinationItem both are not empty
    var searchLocation : String?
    
    var forsegmentControlStartItem: MKMapItem?
    
    @IBOutlet weak var drawRouteButton: UIButton!
    
    var start = true
    
    var forsegmentControlDestinationItem : MKMapItem?
//    var destinationAnnotation : CustomPointAnnotation?
    
    @IBOutlet weak var transportControl: UISegmentedControl!
    
    
    @IBOutlet weak var startButton: UIButton!
    
    var startItem : MKMapItem?
    
    var destinationItem : MKMapItem?
    
    var calculateRoute = true
    
    override func viewDidLoad() {
        zoomTag = 0
        super.viewDidLoad()
        MapView.delegate = self
        MapView.showsScale = true
        MapView.showsBuildings = true
        MapView.showsUserLocation = true
        MapView.showsPointsOfInterest = true
        MapView.mapType = MKMapType.standard
        self.transportControl.setEnabled(false, forSegmentAt: 0)
        self.transportControl.setEnabled(false, forSegmentAt: 1)
        self.startButton.isHidden = true
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
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let mapCamera = MKMapCamera()
        mapCamera.centerCoordinate = userLocation.coordinate
        mapCamera.pitch = 50
        mapCamera.altitude = 500
        mapCamera.heading = newHeading.magneticHeading
        MapView.setCamera(mapCamera, animated: true)
    }
    
    
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        
        if self.startItem != nil && self.destinationItem != nil{
            if calculateRoute == true{
                self.MapView.addAnnotations(self.getTargetNearbyFacilities(annotation: addSearchItem(mapItem: self.destinationItem!)))
                self.MapView.addAnnotations(self.getTargetNearbyFacilities(annotation: addSearchItem(mapItem: self.startItem!)))
                drawRoute(startItem: self.startItem!, destinationItem: self.destinationItem!)
                calculateRoute = false
                let nearbyAnnotationList = getNearbyFacilities()
                if nearbyAnnotationList.count == 0{
                    if displaySourceTag == true{
                        displayErrorMessage(title: "Out of boundry", message: "Sorry, you are not in cbd, that is all we can help")
                        displaySourceTag = false
                    }
                }else{
                    MapView.addAnnotations(nearbyAnnotationList)
                }
            }
        }else if self.startItem == nil && self.destinationItem != nil{
            if calculateRoute == true{
                let destinationAnnotation = self.addSearchItem(mapItem: self.destinationItem!)
                self.MapView.selectAnnotation(destinationAnnotation, animated: true)
                self.MapView.addAnnotations(self.getTargetNearbyFacilities(annotation: destinationAnnotation))
                let nearbyAnnotationList = getNearbyFacilities()
                print(self.annotationList.count)
                if nearbyAnnotationList.count == 0{
                    if displaySourceTag == true{
                        displayErrorMessage(title: "Out of boundry", message: "Sorry, you are not in cbd, that is all we can help")
                        displaySourceTag = false
                    }
                }else{
                    MapView.addAnnotations(nearbyAnnotationList)
                }
            drawRoute(startItem: self.changeLocationToMapItem(location: self.userLocation), destinationItem: self.destinationItem!)
                calculateRoute = false
            }
        }else{
            if nearby {
                let nearbyAnnotationList = getNearbyFacilities()
                if nearbyAnnotationList.count == 0{
                    if displaySourceTag == true{
                    displayErrorMessage(title: "Out of boundry", message: "Sorry, you are not in cbd, that is all we can help")
                    displaySourceTag = false
                    }
                }else{
                    MapView.addAnnotations(nearbyAnnotationList)
                }
            }else{
                mapView.addAnnotations(self.annotationList)
            }
        }
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

        if zoomTag == 0  && self.destinationItem == nil{
           locateLocation(location: userLocation)
            zoomTag = 1
        }
        
        let rad = CLLocationDistance(500)
        let newCircle = MKCircle(center: CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), radius: rad)
        newCircle.title = "location circle"
        MapView.add(newCircle)
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.MapView.removeOverlays(self.MapView.overlays)
        self.destination = CLLocation(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)

        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: (self.destination?.coordinate)!, span: span)
        mapView.setRegion(region, animated: true)

    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        self.transportControl.setEnabled(false, forSegmentAt: 0)
        self.transportControl.setEnabled(false, forSegmentAt: 1)
        manager.stopUpdatingHeading()
        self.startButton.isHidden = true
        self.drawRouteButton.isHidden = false
        mapView.camera.pitch = 0
        MapView.setCamera(mapView.camera, animated: true)
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

        if self.destination == nil{
            displayErrorMessage(title: "No destination", message: "Sorry please select a destination first")
        }else{

            let destinationPlacemark = MKPlacemark(coordinate: (self.destination?.coordinate)!)
            var sourcePlacemark = MKPlacemark(coordinate: (self.userLocation.coordinate))
            var sourceItem = MKMapItem(placemark: sourcePlacemark)
            let destItem = MKMapItem(placemark: destinationPlacemark)
            self.drawRoute(startItem: sourceItem, destinationItem: destItem)
    }
    }
    
    
    func drawRoute(startItem: MKMapItem, destinationItem:MKMapItem){
        MapView.removeOverlays(MapView.overlays)
        self.drawRouteButton.isHidden = true
        self.startButton.isHidden = false
        self.transportControl.setEnabled(true, forSegmentAt: 0)
        self.transportControl.setEnabled(true, forSegmentAt: 1)
        if self.transportControl.selectedSegmentIndex != 0 && self.transportControl.selectedSegmentIndex != 1{
            self.transportControl.selectedSegmentIndex = 0
        }
        self.forsegmentControlStartItem = startItem
        self.forsegmentControlDestinationItem = destinationItem
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = startItem
        directionRequest.destination = destinationItem
        switch self.transportControl.selectedSegmentIndex{
        case 0:
            directionRequest.transportType = .walking
        case 1:
            directionRequest.transportType = .automobile
        default:
            directionRequest.transportType = .walking
        }
        
        directionRequest.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate(completionHandler: { (response, error) in
            guard let response = response else{
                if let error = error{
                    self.transportControl.setEnabled(false, forSegmentAt: 0)
                    self.transportControl.setEnabled(false, forSegmentAt: 1)
                    print(error)
                    //https://stackoverflow.com/questions/28152526/how-do-i-open-phone-settings-when-a-button-is-clicked
                    let alertView = UIAlertController(title: "Error ", message: "No Permission about the Location Service or Internet Connection, Want to change your setting?", preferredStyle: .alert)
                    var settingAction = UIAlertAction(title: "Change Setting", style: .default, handler: { action in
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
                for step in item.steps{
                    print(step.instructions)
                }
                item.polyline.title = startItem.name! + " to " + destinationItem.name!
                item.polyline.subtitle = "\(item.distance)"
                self.MapView.add(item.polyline, level:.aboveRoads )
                let rekt = item.polyline.boundingMapRect
                self.MapView.setRegion(MKCoordinateRegionForMapRect(rekt), animated: true)
            }
            
            // if the distance recommend user not to walk
            if  routes[0].distance > 2500 && directionRequest.transportType == .walking{
                self.alert(title: "Distance Too Long", message: "It might be too far for you, please try other ways to commute")
            }
        })
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
    
    
    func getNearbyFacilities()->[CustomPointAnnotation]{
        var nearbyAnnotation : [CustomPointAnnotation] = []
        for annotation in self.annotationList {
            let  target = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            let distance = (userLocation.distance(from: target)/1000)
            if distance < defaultdistance{
                nearbyAnnotation.append(annotation)
            }
        }
        return nearbyAnnotation
    }
    
    func getTargetNearbyFacilities(annotation: CustomPointAnnotation)->[CustomPointAnnotation]{
        var nearbyAnnotation : [CustomPointAnnotation] = []
        let destinationLocation:CLLocation = CLLocation(latitude: (annotation.coordinate.latitude), longitude: (annotation.coordinate.longitude))
        for annotation in self.annotationList {
            let  target = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            
            let distance = (destinationLocation.distance(from: target)/1000)
            if distance < defaultdistance{
                nearbyAnnotation.append(annotation)
            }
        }
        return nearbyAnnotation
    }
    
    func displayErrorMessage(title:String, message: String){
        let alertview = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertview.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alertview, animated: true, completion: nil)
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        self.performSegue(withIdentifier: "showInformation", sender: self)
    }
    
    func addSearchItem(mapItem: MKMapItem) -> CustomPointAnnotation{
        let annotation = CustomPointAnnotation()
        annotation.title = mapItem.placemark.name
        annotation.subtitle = mapItem.placemark.title
        annotation.imageName = "map-marker-2-40"
        annotation.coordinate = mapItem.placemark.coordinate
        self.MapView.addAnnotation(annotation)
        return annotation
    }
    
    @IBAction func functionIsChanged(_ sender: Any) {
        self.drawRoute(startItem: self.forsegmentControlStartItem!, destinationItem: self.forsegmentControlDestinationItem!)
    }
    
    @IBAction func startIsClicked(_ sender: Any) {
        if start == true{
        self.manager.startUpdatingHeading()
            start = false
        }else{
            start = true
            self.manager.stopUpdatingHeading()
            self.locateLocation(location: self.userLocation)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showInformation"{
            let controller = segue.destination as! InformationViewController
            controller.userLocation = self.userLocation
            controller.destination = self.destination
            controller.hiddenMessage = (self.MapView.selectedAnnotations[0] as! CustomPointAnnotation).hiddenMessage
        }
    }
    
    //change Location To MKMapItem
    func changeLocationToMapItem(location:CLLocation) -> MKMapItem {
        let placemark : MKPlacemark = MKPlacemark(coordinate: location.coordinate)
        let item : MKMapItem = MKMapItem(placemark: placemark)
        return item
    }
    
    
}




