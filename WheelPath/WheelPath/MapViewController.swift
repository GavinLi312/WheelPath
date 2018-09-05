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

    
    var search = false
    
    var searchLocation : String?
    
    var destinationAnnotation : CustomPointAnnotation?
    
    @IBOutlet weak var transportControl: UISegmentedControl!
    
    
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


    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {



        
        if nearby || search{
            let nearbyAnnotationList = getNearbyFacilities()
            if nearbyAnnotationList.count == 0 && displaySourceTag == true{
                displayErrorMessage(title: "Out of boundry", message: "Sorry, you are not in cbd, that is all we can help")
                displaySourceTag = false
            }else{
                MapView.addAnnotations(nearbyAnnotationList)
            }
            if search {
                searchForLocation(location: self.searchLocation!)
                search = false
            }
            
            
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

        if zoomTag == 0  && search == false{
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
        self.transportControl.setEnabled(true, forSegmentAt: 0)
        self.transportControl.setEnabled(true, forSegmentAt: 1)
        print(self.transportControl.selectedSegmentIndex)
        if self.transportControl.selectedSegmentIndex != 0 && self.transportControl.selectedSegmentIndex != 1{
            self.transportControl.selectedSegmentIndex = 0
        }
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
                        print(error)
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
                if  routes[0].distance > 2500 && directionRequest.transportType == .walking{
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
    
    func getDestinationNearbyFacilities()->[CustomPointAnnotation]{
        var nearbyAnnotation : [CustomPointAnnotation] = []
        let destinationLocation:CLLocation = CLLocation(latitude: (destinationAnnotation?.coordinate.latitude)!, longitude: (destinationAnnotation?.coordinate.longitude)!)
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
    
    func searchForLocation(location: String){
        //ignoring User
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        //Activity Indicator
        
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        self.view.addSubview(activityIndicator)
        
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = location
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start{
            (response,error) in
            
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            if response == nil{
                print("ERROR")
            }else{
                //Remove annotations
                let mapitem = response?.mapItems.first

                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                //Create annotation
                let annotation = CustomPointAnnotation()
                annotation.title = mapitem?.name
                annotation.subtitle = mapitem?.placemark.title
                annotation.imageName = "map-marker-2-40"
                annotation.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.destinationAnnotation = annotation
                self.MapView.addAnnotation(self.destinationAnnotation!)
                self.MapView.addAnnotations(self.getDestinationNearbyFacilities())
                
                
                
                let searchTarget = CLLocationCoordinate2DMake(latitude!, longitude!)
                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                let region = MKCoordinateRegion(center: searchTarget, span: span)
                self.MapView.setRegion(region, animated: true)
                
                let rad = CLLocationDistance(self.defaultdistance)
                let destinationCircle = MKCircle(center: CLLocationCoordinate2DMake(latitude!, longitude!), radius: rad)
//                destinationCircle.title = "destination circle"
                self.MapView.add(destinationCircle)
                if mapitem?.placemark.postalCode != nil{
                    if cbdPostcode.contains((mapitem?.placemark.postalCode)!) == false{
                        self.displayErrorMessage(title: "Out of Boundry", message: "The place you want to go is out of cbd")
                    }
                }else{
                    self.displayErrorMessage(title: "Error", message: "The system doesn't have the post code information of the destination")
                }
            }
            
        }
    }
    @IBAction func functionIsChanged(_ sender: Any) {
        self.navigationButtonClicked(self)
    }
    
    

}




