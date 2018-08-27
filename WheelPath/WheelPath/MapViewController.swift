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
let colors = [UIColor.black,UIColor.blue,UIColor.brown,UIColor.green,UIColor.orange]
var zoomTag = 0
class MapViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var MapView: MKMapView!
    let manager = CLLocationManager()
    var option : String?
    var annotationList : [CustomPointAnnotation] = []
    var userLocation : CLLocation = CLLocation()
    let defaultdistance = 0.5
    var destination : CLLocation?
    
    // initialize the map
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

    override func viewWillAppear(_ animated: Bool) {
        annotationList.removeAll()
        switch option {
        case functionList[0]:
            putToiletsOnMap()
        case functionList[1]:
            putWaterFountainOnMap()
        default:
            print("No Option is selected right now")
        }
        MapView.removeAnnotations(MapView.annotations)
        MapView.addAnnotations(self.annotationList)
    }
    
    
    //https://www.hackingwithswift.com/example-code/system/how-to-run-code-after-a-delay-using-asyncafter-and-perform
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if option == nil{
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if functions.object(forKey: functionList[0] as! NSString) != nil{
                    self.MapView.addAnnotations(self.getNearbyFacilities())
                }
            }
        }
        
    }
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
    
//        MapView.setRegion(region, animated: false)
        manager.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // show user's location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        userLocation = location
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude), span: span)
        if zoomTag == 0{
            MapView.setRegion(region, animated: true)
            zoomTag = 1
        }
        let rad = CLLocationDistance(500)
        let circle = MKCircle(center: CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), radius: rad)
        MapView.add(circle)
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.destination = CLLocation(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        
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
                annotation.imageName = "toilet-20"
            }else{
                annotation.imageName = "toilet-no-20"
            }
            self.annotationList.append(annotation)
        }
        }
    
    
    func putWaterFountainOnMap(){

        let waterFountains = functions.object(forKey: functionList[1] as! NSString) as! [WaterFountain]
        for fountain in waterFountains{
            var annotation = CustomPointAnnotation()
            annotation.title = fountain.id!
            annotation.subtitle = fountain.desc!
            annotation.coordinate = CLLocationCoordinate2DMake(fountain.latitude!, fountain.longitude!)
            if fountain.disableFlag == "Yes"{
                annotation.imageName = "water-20"
            }else{
                annotation.imageName = "water-no-20"
            }
            self.annotationList.append(annotation)
        }
        
    }
    
    func getNearbyFacilities() -> [CustomPointAnnotation]{
        var nearbyAnnotation : [CustomPointAnnotation] = []
        putWaterFountainOnMap()
        putToiletsOnMap()
        for annotation in self.annotationList {
            let  target = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            let distance = (userLocation.distance(from: target)/1000)
            if distance < defaultdistance{
                nearbyAnnotation.append(annotation)
            }
        }
        return nearbyAnnotation
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
            print(" i am nil")
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
                print(response.routes.count)
                let routes = response.routes
                for item in routes{
                    print(item.distance)
                self.MapView.add(item.polyline, level:.aboveRoads )
                let rekt = item.polyline.boundingMapRect
                self.MapView.setRegion(MKCoordinateRegionForMapRect(rekt), animated: true)
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
    }


