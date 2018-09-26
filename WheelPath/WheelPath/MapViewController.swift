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
import UserNotifications


var zoomTag = 0
var firstLaunch = true

protocol searchForDestination {
    func searchforDestination(destination:MKMapItem, startPoint:MKMapItem?)
}

class MapViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate, searchForDestination {


    @IBOutlet weak var MapView: MKMapView!

    
    let manager = CLLocationManager()
    
    
    var annotationList : [AccessibleFacilities] = []
    
    var userLocation : CLLocation?
    
    let defaultdistance = 0.5
    
    var destination : CLLocation?
    // if search and nearby are true, the route will be showen
    // startItem and destinationItem both are not empty
    var searchLocation : String?
    
    var forsegmentControlStartItem: MKMapItem?
    
    @IBOutlet weak var drawRouteButton: UIButton!
    
    var start = true
    
    var forsegmentControlDestinationItem : MKMapItem?
    
    var coords: [CLLocationCoordinate2D] = []
    
    //list just to store toilets and water fountains
//    var toiletsAndWaterFountainList : [CustomPointAnnotation] = []
    
    @IBOutlet weak var transportControl: UISegmentedControl!
    
    @IBOutlet weak var locateMe: UIButton!
    
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var DistanceLabel: UILabel!
    
    @IBOutlet weak var InstructionLabel: UILabel!
    
    @IBOutlet weak var navigationView: UIView!
    
    var startItem : MKMapItem?
    
    var startAnnotation : CustomPointAnnotation?
    
    var destinationItem : MKMapItem?
    
    var destinationAnnotation: CustomPointAnnotation?
    
    
    var calculateRoute = true
    
    var alongWithTheRoute : [AccessibleFacilities] = []
    
    var routeSteps : [MKRouteStep] = []
    
    //to check internet connection
    var reachability : Reachability?
    
    //database
    var databaseRef : DatabaseReference?
    
    var publicToiletList : [AccessibleFacilities] = []
    
    var waterFountainList : [AccessibleFacilities] = []
    
    var accessibleBuildingList : [AccessibleFacilities] = []
    
    var publicToiltToiletAnnotationList: [AccessibleFacilities] = []
    
    var parkingspots: [AccessibleFacilities] = []
    
    let activityIndicator = UIActivityIndicatorView()
    
    var steepnessList:[Steepness] = []
    
    @IBOutlet weak var buttonControl: UIButton!
    
    var buttonControlSelected = false
    
    @IBOutlet weak var nearbyButton: UIButton!
    
    @IBOutlet weak var accessibleBuildingButton: UIButton!
    
    @IBOutlet weak var toiletButton: UIButton!
    
    @IBOutlet weak var waterButton: UIButton!
    
    @IBOutlet weak var functionView: UIView!
    
    override func viewDidLoad() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge], completionHandler: {
            didAllow,error in
        })
        self.reachability = Reachability.init()
        zoomTag = 0
        super.viewDidLoad()
        self.navigationView.isHidden = true
        self.navigationView.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        self.navigationView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.7018407534)
        MapView.delegate = self
        MapView.showsScale = true
        MapView.showsBuildings = false
        MapView.showsUserLocation = true
        MapView.showsPointsOfInterest = false
        MapView.mapType = MKMapType.standard
        self.transportControl.setEnabled(false, forSegmentAt: 0)
        self.transportControl.setEnabled(false, forSegmentAt: 1)
        self.transportControl.isHidden = true
        self.transportControl.layer.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
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
        
        functionView.isHidden = true

        manager.allowsBackgroundLocationUpdates = true
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        registerAnnotationViewClasses()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if accessibleBuildingList.count == 0 {
        if ((self.reachability!.connection) == .cellular || (self.reachability!.connection == .wifi)){
            
            UIApplication.shared.beginIgnoringInteractionEvents()
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
            activityIndicator.center = self.view.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.startAnimating()
            self.view.addSubview(activityIndicator)

            databaseRef = Database.database().reference()
            getPublicToiletsData()
            getWaterFountainData()
            getAccessibleBuildings()
            getSteepnessData()
        }else{
            displayErrorMessage(title: "Error", message: "Not internet Connection")
            }
        }
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        if self.start == false{
            self.startIsClicked(self)
        }

    }
    
    //https://www.hackingwithswift.com/example-code/system/how-to-run-code-after-a-delay-using-asyncafter-and-perform
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let mapCamera = MKMapCamera()
        mapCamera.centerCoordinate = (userLocation?.coordinate)!
        mapCamera.pitch = 50
        mapCamera.altitude = 500
        mapCamera.heading = newHeading.magneticHeading
        MapView.setCamera(mapCamera, animated: true)
        let userPlaceMark = MKPlacemark(coordinate: (self.userLocation?.coordinate)!)
        let userItem = MKMapItem(placemark: userPlaceMark)
    }
    
    //get public Toilets Data from firebase
    func getPublicToiletsData(){
        let toiletsRef =  databaseRef?.child(functionList[0])
        toiletsRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            for item in value.allKeys{
                let toiletInfo = value.object(forKey: item) as! NSDictionary
                var publicToilet = AccessibleFacilities()
                publicToilet.id = (item as! String)
                publicToilet.category = toiletInfo.object(forKey: "Category") as! String
                publicToilet.detail = toiletInfo.object(forKey: "Details") as! String
                publicToilet.desc = toiletInfo.object(forKey: "Description") as! String
                publicToilet.disableFlag = toiletInfo.object(forKey: "DisableFlag") as! String
                if publicToilet.disableFlag == "Yes"{
                    publicToilet.type = AccessibleFacilityType.accessiblePublicToilet
                }else{
                    publicToilet.type = AccessibleFacilityType.inaccessiblePublicToilet
                }
                publicToilet.latitude = toiletInfo.object(forKey: "Latitude") as! Double
                publicToilet.longitude = toiletInfo.object(forKey: "Longitude") as! Double

                self.publicToiletList.append(publicToilet)
            }
           self.annotationList.append(contentsOf: self.publicToiletList)
            
            self.publicToiltToiletAnnotationList.append(contentsOf: self.publicToiletList)
        })
        
    }
    
    // get waterfountain data from firebase
    func getWaterFountainData(){
        let waterRef =  databaseRef?.child(functionList[1])
        waterRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            
            for item in value.allKeys{
                let waterInfo = value.object(forKey: item) as! NSDictionary
                var waterFountain = AccessibleFacilities()
                waterFountain.id = item as! String
                waterFountain.type = AccessibleFacilityType.waterFountain
                waterFountain.desc = waterInfo.object(forKey: "Description") as! String
                waterFountain.detail = waterInfo.object(forKey: "Details") as! String
                waterFountain.category = waterInfo.object(forKey: "Category") as! String
                waterFountain.disableFlag = waterInfo.object(forKey: "DisableFlag") as! String
                waterFountain.latitude = waterInfo.object(forKey: "Latitude") as! Double
                waterFountain.longitude = waterInfo.object(forKey: "Longitude") as! Double
                self.waterFountainList.append(waterFountain)
            }
            self.annotationList.append(contentsOf: self.waterFountainList)
            self.publicToiltToiletAnnotationList.append(contentsOf: self.waterFountainList)
        })
    }
    
    //get accessible buildings from firebase
    func getAccessibleBuildings(){
        let accessibleBuildingsRef = databaseRef?.child(functionList[2]).queryOrdered(byChild: "DisableFlag").queryEqual(toValue: "Yes")
        accessibleBuildingsRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            for item in value.allKeys{
                let buildingInfo = value.object(forKey: item) as! NSDictionary
                var building = AccessibleFacilities()
                building.type = AccessibleFacilityType.accessibleBuilding
                building.id = item as! String
                building.category = buildingInfo.object(forKey: "Category") as! String
                building.detail = buildingInfo.object(forKey: "Details") as! String
                building.desc = buildingInfo.object(forKey: "Description") as! String
                building.disableFlag = buildingInfo.object(forKey: "DisableFlag") as! String
                building.latitude = buildingInfo.object(forKey: "Latitude") as! Double
                building.longitude = buildingInfo.object(forKey: "Longitude") as! Double
                self.accessibleBuildingList.append(building)
                
            }
            self.annotationList.append(contentsOf: self.accessibleBuildingList)
            
        })
    }
    
    //get steepness data from database
    func getSteepnessData(){
        let steepnessRef = databaseRef?.child("SteepNess")
        steepnessRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            for item in value.allKeys{
                let steepInfo = value.object(forKey: item) as! NSDictionary
                var steepness = Steepness()
                steepness.steepnessFlag = steepInfo.object(forKey: "SteepFlag") as! Int
                steepness.coordinates = steepInfo.object(forKey: "coordinates") as! [[[[Double]]]]
                self.steepnessList.append(steepness)
            }
            for item in self.steepnessList{
                self.MapView.add(self.drawShap(coornidatesArray: self.changeArrayToCoornidates(points: item.coordinates), steepnessLevel: item.steepnessFlag))
                
            }
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            if firstLaunch{
                firstLaunch = false
                self.nearbyButtonClicked(self)
            }
        })
        
    }
    
        func changeArrayToCoornidates(points:[[[[Double]]]]) -> [CLLocationCoordinate2D] {
            var coordinateArray : [CLLocationCoordinate2D] = []
            for layer1 in points{
                for layer2 in layer1{
                    for layer3 in layer2{
                        let coordinate = CLLocationCoordinate2DMake(layer3.last!, layer3.first!)
                        coordinateArray.append(coordinate)
                    }
                }
            }
            return coordinateArray
        }
    
    
        //https://stackoverflow.com/questions/45038869/swift-mapkit-create-a-polygon
    func drawShap(coornidatesArray:[CLLocationCoordinate2D],steepnessLevel: Int) -> custommkPolygon{
    
        let polygon = custommkPolygon(coordinates: coornidatesArray, count: coornidatesArray.count)
        polygon.colorLevel = steepnessLevel
        return polygon
    
    }
    
    func registerAnnotationViewClasses() {
        MapView.register(UsableToiletAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        MapView.register(UnusableToiletAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        MapView.register(WaterFountainAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        MapView.register(AccessibleBuildingAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        MapView.register(ParkingSpotAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
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
            locateLocation(location: userLocation!)
            zoomTag = 1
        }
        
        let rad = CLLocationDistance(500)
        let newCircle = MKCircle(center: CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), radius: rad)
        newCircle.title = "location circle"
        MapView.add(newCircle)
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        removeNotification()
        
        self.buttonControl.isHidden = false
        self.transportControl.setEnabled(false, forSegmentAt: 0)
        self.transportControl.setEnabled(false, forSegmentAt: 1)
        self.transportControl.isHidden = true
        manager.stopUpdatingHeading()
        for overlay in self.MapView.overlays{
            if overlay is MKPolyline{
                self.MapView.remove(overlay)
            }
        }
        if  self.start == false{
            self.startIsClicked(self)
            self.startButton.isHidden = true
            self.drawRouteButton.isHidden = false
        }
        
        if self.startButton.isHidden == false{
            self.startButton.isHidden = true
            
        }
        if self.drawRouteButton.isHidden == true{
            self.drawRouteButton.isHidden = false
        }
        self.destination = CLLocation(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: (self.destination?.coordinate)!, span: span)
        mapView.setRegion(region, animated: false)
    }
    
    

    // add anotation in the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        guard let facilityannotation = annotation as?  AccessibleFacilities else {
            let customAnnotation = annotation as? CustomPointAnnotation
            let btn = UIButton(type: .infoDark) as UIButton

            if !(customAnnotation is MKPointAnnotation){
                return nil
            }
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "facility")
            if annotationView == nil{
                annotationView = MKAnnotationView(annotation: customAnnotation, reuseIdentifier: "facility")
                annotationView!.canShowCallout = true
            }
            else {
                annotationView!.annotation = customAnnotation
            }

            let image = customAnnotation as! CustomPointAnnotation
            annotationView?.rightCalloutAccessoryView = btn


            annotationView!.image = UIImage(named: image.imageName)
            return annotationView
        }
        
        switch facilityannotation.type! {
        case .accessiblePublicToilet:
            return UsableToiletAnnotationView(annotation: annotation, reuseIdentifier: UsableToiletAnnotationView.ReuseID)
        case .inaccessiblePublicToilet:
            return UnusableToiletAnnotationView(annotation: annotation, reuseIdentifier: UnusableToiletAnnotationView.ReuseID)
        case .waterFountain:
            return WaterFountainAnnotationView(annotation: annotation, reuseIdentifier: WaterFountainAnnotationView.ReuseID)
        case .accessibleBuilding:
            return AccessibleBuildingAnnotationView(annotation: annotation, reuseIdentifier: AccessibleBuildingAnnotationView.ReuseID)

        case .parkingSpot:
            return ParkingSpotAnnotationView(annotation: annotation, reuseIdentifier: ParkingSpotAnnotationView.ReuseID)
        }

    }
    

    @IBAction func navigationButtonClicked(_ sender: Any) {
        if ((self.reachability!.connection) == .cellular || (self.reachability!.connection == .wifi)){
            if self.destination == nil{
                displayErrorMessage(title: "No destination", message: "Sorry please select a destination first")
            }else{
                let destinationPlacemark = MKPlacemark(coordinate: (self.destination?.coordinate)!)
                destinationItem = MKMapItem(placemark: destinationPlacemark)
                if self.destinationAnnotation != nil{
                self.MapView.removeAnnotation(self.destinationAnnotation!)
                }
                self.destinationAnnotation = self.addSearchItem(mapItem: destinationItem!, imageName: "pin-end 3-40")
                if startItem == nil{
                    if userLocation != nil{
                        var sourcePlacemark = MKPlacemark(coordinate: (self.userLocation?.coordinate)!)
                        var sourceItem = MKMapItem(placemark: sourcePlacemark)
                        self.drawRoute(startItem: sourceItem, destinationItem: destinationItem!)
                    }else{
                        locationServiceIsNotGivenErrorMessage()
                    }

                }else{
                    self.drawRoute(startItem: self.startItem!, destinationItem: destinationItem!)
                }
            }
        }else{
              displayErrorMessage(title: "Error", message: "No internet Connection")
        }
    }
    

    
    func drawRoute(startItem: MKMapItem, destinationItem:MKMapItem){

        for overlay in self.MapView.overlays{
            if overlay is MKPolyline{
                self.MapView.remove(overlay)
            }
        }
        
        // remove notification
        removeNotification()
        self.buttonControl.isHidden = true
        if self.buttonControlSelected{
            self.functionListButtonClicked(self)
        }
        self.transportControl.isHidden = false
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
                    self.buttonControl.isHidden = false
                    self.transportControl.isHidden = true
                    self.transportControl.setEnabled(false, forSegmentAt: 0)
                    self.transportControl.setEnabled(false, forSegmentAt: 1)
                    print(error)
                    //https://stackoverflow.com/questions/28152526/how-do-i-open-phone-settings-when-a-button-is-clicked
                    let alertView = UIAlertController(title: "Error ", message: "No routes are found", preferredStyle: .alert)
                    alertView.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { action in
                        print(" no is clicked")
                        
                    }))
                    self.present(alertView, animated: false, completion: nil)
                }
                return
            }
            if self.userLocation != nil{
                self.drawRouteButton.isHidden = true
                if self.startItem == nil{
                self.startButton.isHidden = false
                }
            }
            let routes = response.routes
            
            let item = routes.first!
            self.routeSteps = item.steps
                item.polyline.title = startItem.name! + " to " + destinationItem.name!
                item.polyline.subtitle = "\(item.distance)"
                var coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: item.polyline.pointCount)
                item.polyline.getCoordinates(coordsPointer, range: NSMakeRange(0, item.polyline.pointCount))
                for i in 0..<item.polyline.pointCount {
                    self.coords.append(coordsPointer[i])
                }
                
                self.MapView.removeAnnotations(self.alongWithTheRoute)
                var annotationList : [AccessibleFacilities] = []

                for item in self.coords{
                    let temp = AccessibleFacilities()
                    temp.latitude = item.latitude
                    temp.longitude = item.longitude
                    let nearbyFacilities = self.getTargetNearbyFacilities(annotation: temp, range: 0.1)
                    let mapAnnotations = self.MapView.annotations
                    
                    
                    for facility in nearbyFacilities{
                        if mapAnnotations.contains(where: {$0.coordinate.latitude == facility.coordinate.latitude && $0.coordinate.longitude == facility.coordinate.longitude}) || self.alongWithTheRoute.contains(facility){
                            
                        }else{
                            annotationList.append(facility)
                        }
                    }
                }
            
//                print(annotationList.count)
//                print(self.annotationList.count)
                self.alongWithTheRoute.removeAll()
                self.alongWithTheRoute.append(contentsOf: annotationList)
                print(self.alongWithTheRoute.count)
                self.MapView.addAnnotations(self.alongWithTheRoute)
                self.MapView.add(item.polyline, level:.aboveRoads )
                let rekt = item.polyline.boundingMapRect

            let  newSize = MKMapSize(width: (rekt.size.width * 1.1), height: (rekt.size.height ))
            let newReke = MKMapRect(origin: rekt.origin , size: newSize)
                self.MapView.setRegion(MKCoordinateRegionForMapRect(newReke), animated: false)

            if  routes[0].distance > 2500 && directionRequest.transportType == .walking{
                self.alert(title: "Distance Too Long", message: "It might be too far for you, please try other ways to commute")
            }
        })
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline{
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        renderer.lineWidth = 5.0
        return renderer
        }else if overlay is MKCircle{
            let circleView = MKCircleRenderer(overlay: overlay)
            circleView.strokeColor = UIColor.clear
            if overlay.title == "location circle"{
            circleView.fillColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 0.2004762414)
            }else{
                circleView.fillColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 0.2958315497)
            }
            return circleView
        }else if overlay is MKPolygon{
            let polygon = overlay as! custommkPolygon
            let polygonView = MKPolygonRenderer(overlay: overlay)
            switch polygon.colorLevel{
            case 1:
                polygonView.fillColor = #colorLiteral(red: 0.5326765776, green: 0, blue: 0.6681495309, alpha: 0.5)
            case 2:
                polygonView.fillColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 0.5042540668)
            case 3:
                polygonView.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
            default:
                polygonView.fillColor = #colorLiteral(red: 0.3748460412, green: 0.6896326542, blue: 0.1897849143, alpha: 0.5)
                
            }
            return polygonView
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
        if startItem != nil{
            self.startItem = nil
        }
        if userLocation == nil{
            locationServiceIsNotGivenErrorMessage()
        }else{
        locateLocation(location: userLocation!)
        }
    }
    
    
    func getNearbyFacilities()->[AccessibleFacilities]{
        var nearbyAnnotation : [AccessibleFacilities] = []
        if userLocation != nil{
        for annotation in self.annotationList {
            let  target = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            let distance = ((userLocation?.distance(from: target))!/1000)
            if distance < defaultdistance{
                nearbyAnnotation.append(annotation)
            }
            }}else{
           locationServiceIsNotGivenErrorMessage()
        }
        return nearbyAnnotation
    }
    
    func getTargetNearbyFacilities(annotation: AccessibleFacilities, range: Double)->[AccessibleFacilities]{
        var nearbyAnnotation : [AccessibleFacilities] = []
        let destinationLocation:CLLocation = CLLocation(latitude: (annotation.coordinate.latitude), longitude: (annotation.coordinate.longitude))
        for annotation in self.publicToiltToiletAnnotationList {
            let  target = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            let distance = (destinationLocation.distance(from: target)/1000)
            if distance < range {
                nearbyAnnotation.append(annotation)
            }
        }
//        print(nearbyAnnotation.count)
        return nearbyAnnotation
    }
    
    func displayErrorMessage(title:String, message: String){
        let alertview = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertview.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alertview, animated: true, completion: nil)
    }
    
    // if both user location and start item are nil, the function of turning to another page, should be negative
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if self.userLocation != nil || self.startItem != nil{
            self.performSegue(withIdentifier: "showInformation", sender: self)
        }else{
            locationServiceIsNotGivenErrorMessage()
        }
    }
//
    func addSearchItem(mapItem: MKMapItem,imageName: String) -> CustomPointAnnotation{
        let newFacility = CustomPointAnnotation()
        newFacility.title = mapItem.placemark.name
        newFacility.subtitle = mapItem.placemark.title
        newFacility.imageName = imageName
        newFacility.coordinate = mapItem.placemark.coordinate
        self.MapView.addAnnotation(newFacility)
        return newFacility
    }
    
    
    @IBAction func functionIsChanged(_ sender: Any) {
        if self.start == false{
            self.startIsClicked(self)
        }
        self.drawRoute(startItem: self.forsegmentControlStartItem!, destinationItem: self.forsegmentControlDestinationItem!)
    }
    
    
    @IBAction func startIsClicked(_ sender: Any) {
        if start == true{
            self.manager.startUpdatingHeading()
            self.navigationView.isHidden = false
            self.DistanceLabel.text = "\((self.routeSteps.first?.distance)!) m "
            
            if self.routeSteps.first?.instructions == ""{
                self.InstructionLabel.text = "Move Forward"
            }else{
                self.InstructionLabel.text = "\(Int((self.routeSteps.first?.instructions)!)!)"
            }
            start = false
            self.startButton.setImage(UIImage(named: "stop copy-76"), for: .normal)
            for step in self.routeSteps{
            self.addnotificationToStep(step: step)
            }
        }else{
            self.navigationView.isHidden = true
            start = true
            self.startButton.setImage(UIImage(named: "start-76"), for: .normal)
            self.manager.stopUpdatingHeading()
            self.locateLocation(location: self.userLocation!)
            removeNotification()
        }
    }
    
    func removeNotification() {
        UNUserNotificationCenter.current().getPendingNotificationRequests{(notificationRequests) in
            var identifiers : [String] = []
            for notification in notificationRequests{
                identifiers.append(notification.identifier)
            }
            print(identifiers.count)
            if identifiers.count > 0{
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            }
        }
        for item in self.manager.monitoredRegions{
            self.manager.stopMonitoring(for: item)
        }
        
        for item in MapView.overlays{
            if item is MKCircle{
                if item.title != "location circle"{
                    self.MapView.remove(item)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showInformation"{
            let controller = segue.destination as! InformationViewController
            if self.startItem == nil{
                controller.userLocation = self.userLocation
                
            }else{
                controller.userLocation = CLLocation(latitude: (self.startItem?.placemark.coordinate.latitude)!, longitude: (self.startItem?.placemark.coordinate.longitude)!)
            }
            controller.destination = self.destination
            controller.hiddenMessage = (self.MapView.selectedAnnotations[0] as! AccessibleFacilities).title!
            if (self.MapView.selectedAnnotations[0] as! AccessibleFacilities).detail != nil{
                controller.hiddenMessage?.append("\n" + (self.MapView.selectedAnnotations[0] as! AccessibleFacilities).detail!)
            }
        }else if segue.identifier == "searchDestination"{
            let controller = segue.destination as! searchPageController
            controller.searchProtocol = self
        }
    }
    
    //change Location To MKMapItem
    func changeLocationToMapItem(location:CLLocation) -> MKMapItem {
        let placemark : MKPlacemark = MKPlacemark(coordinate: location.coordinate)
        let item : MKMapItem = MKMapItem(placemark: placemark)
        return item
    }
    
    // when the location service is not given,
    func locationServiceIsNotGivenErrorMessage(){
        let alertView = UIAlertController(title: "Location service is not enabled", message: "DO you want to enable the location service?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default, handler:
        { action in
            let settingUrl = NSURL(string: UIApplicationOpenSettingsURLString)
            if let url = settingUrl{
                UIApplication.shared.openURL(url as URL)
            }
            self.navigationController?.popViewController(animated: true)
        })
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: {
            action in
            self.navigationController?.popViewController(animated: true)
        })
        alertView.addAction(yesAction)
        alertView.addAction(noAction)
        self.present(alertView, animated: true, completion: nil)
        
    }
    

    
    // for each step, a notification should be added at the beginning. For the last step, the notification should be added at the destination
    func addnotificationToStep(step: MKRouteStep){
        var coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: step.polyline.pointCount)
        step.polyline.getCoordinates(coordsPointer, range: NSMakeRange(0, step.polyline.pointCount))
        var stepCount : [CLLocationCoordinate2D] = []
        for i in 0 ..< step.polyline.pointCount{
            stepCount.append(coordsPointer[i])
        }
        print(stepCount.count)
        if stepCount.count == 1 {
            print(stepCount.first)
            addNotificationToAPoint(center: stepCount.first!, radius: 10, contentTitle: "First Step", contentSubTitle: "\(step.distance)", contentBody: "First Step", identifier: " First Step")
        }else{
            addNotificationToAPoint(center: stepCount.first!, radius: 30, contentTitle: step.instructions, contentSubTitle: "\(step.distance)", contentBody: step.instructions, identifier: step.instructions)
            }
        
        // add the notification to the last spot
        if step == self.routeSteps.last{
            addNotificationToAPoint(center: stepCount.last!, radius: 30, contentTitle: "Destination", contentSubTitle: "You  arrived at the destination", contentBody: "You  arrived at the destination", identifier: "Destination")
        }
    }
    
    // add notification to a specific point
    func addNotificationToAPoint(center: CLLocationCoordinate2D, radius: Int, contentTitle: String, contentSubTitle: String, contentBody:String, identifier: String) {
        let circle = MKCircle(center: center, radius: CLLocationDistance(radius))
        self.MapView.add(circle)
        let notificationRegion = CLCircularRegion(center: center, radius: CLLocationDistance(radius), identifier: identifier)
        notificationRegion.notifyOnEntry = true
        notificationRegion.notifyOnExit = false
        self.manager.startMonitoring(for: notificationRegion)
        let content = UNMutableNotificationContent()
        content.title = contentTitle
        content.subtitle = contentSubTitle
        content.body = contentBody
        content.badge = 1
        let trigger = UNLocationNotificationTrigger(region: notificationRegion, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

     // when user entered the region. the Distance lable and Instruction Label will be changed with it.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        var distance = Int(findstepByRegion(identifier: region.identifier).distance)
        if distance > 1000 {
            self.DistanceLabel.text = "\(distance/1000) km"
        }else{
            self.DistanceLabel.text = "\(distance) m"
        }
        self.InstructionLabel.text = region.identifier
    }
    
    
    // find step by region, with a specific region a specific region will be given
    func findstepByRegion(identifier:String) -> MKRouteStep {
        var step = self.routeSteps.first
        for item in self.routeSteps{
            if item.instructions == identifier{
                step = item
                break
            }
        }
        return step!
    }
    
    
    @IBAction func functionListButtonClicked(_ sender: Any) {
        if startItem != nil{
            self.startItem = nil
        }
        
        if buttonControlSelected == false{
            self.functionView.isHidden = false
            self.buttonControl.setImage(#imageLiteral(resourceName: "close-76"), for: .normal)
            buttonControlSelected = true
        }else{
            self.functionView.isHidden = true
            self.buttonControl.setImage(#imageLiteral(resourceName: "open-76"), for: .normal)
            buttonControlSelected = false
        }
    }
    
    
    @IBAction func nearbyButtonClicked(_ sender: Any) {
        self.MapView.removeAnnotations(self.MapView.annotations)
        self.MapView.addAnnotations(self.getNearbyFacilities())
        if self.userLocation != nil{
        locateLocation(location: userLocation!)
        }else{
            locationServiceIsNotGivenErrorMessage()
        }
        
    }
    
    @IBAction func buildingButtonIsClicked(_ sender: Any) {
        self.MapView.removeAnnotations(self.MapView.annotations)
        self.MapView.addAnnotations(self.accessibleBuildingList)
    }
    
    @IBAction func toiletButtonIsClicked(_ sender: Any) {
        self.MapView.removeAnnotations(self.MapView.annotations)
            self.MapView.addAnnotations(self.publicToiletList)
        
    }
    
    @IBAction func waterButtonIsClicked(_ sender: Any) {
        self.MapView.removeAnnotations(self.MapView.annotations)
        self.MapView.addAnnotations(self.waterFountainList)
    }
    
    
    @IBAction func parkButtonClicked(_ sender: Any) {
        self.MapView.removeAnnotations(self.MapView.annotations)
        getAvailableParkingSpot(coordinate: (userLocation?.coordinate)!)
    }
    
    func searchforDestination(destination: MKMapItem, startPoint: MKMapItem?) {
        self.nearbyButtonClicked(self)
        if self.startAnnotation != nil{
        self.MapView.removeAnnotation(self.destinationAnnotation!)
        }
        if self.startAnnotation != nil{
            self.MapView.removeAnnotation(self.startAnnotation!)
        }
        if startPoint != nil{
            self.startItem = startPoint
            self.destinationItem = destination
            destinationAnnotation = addSearchItem(mapItem: self.destinationItem!, imageName: "pin-end 3-40")
            startAnnotation = addSearchItem(mapItem: self.startItem!,imageName: "pin-start 3-40")
            self.destination = CLLocation(latitude: (destinationItem?.placemark.coordinate.latitude)!, longitude: (destinationItem?.placemark.coordinate.longitude)!)
            drawRoute(startItem: self.startItem!, destinationItem: self.destinationItem!)
        }else{
            self.destinationItem = destination
            self.startItem = nil
            destinationAnnotation = self.addSearchItem(mapItem: self.destinationItem!, imageName: "pin-end 3-40")
            self.MapView.selectAnnotation(destinationAnnotation!, animated: true)
            self.destination = CLLocation(latitude: (destinationItem?.placemark.coordinate.latitude)!, longitude: (destinationItem?.placemark.coordinate.longitude)!)

            MapView.addAnnotations(getNearbyFacilities())
            if self.userLocation != nil{

            drawRoute(startItem: self.changeLocationToMapItem(location: self.userLocation!), destinationItem: self.destinationItem!)
            }
        }
        
    }
    

    let APIaddress = "https://data.melbourne.vic.gov.au/resource/dtpv-d4pf.json?status=Unoccupied&"
    let APIToken = "&$$app_token=L91hFMhjcf0tTl6cVMT0jOoqD"
    
    func APIQuery(coordinate: CLLocationCoordinate2D)->String{
        return "$where=within_circle(location,\(coordinate.latitude),\(coordinate.longitude),500)"
    }
    
    struct Parking:Decodable {
        let bay_id:String?
        let lat:String?
        let coordinates: [Double]?
        let lon:String?
        let st_marker_id:String?
        let status:String?
    }
    
    
    func getAvailableParkingSpot(coordinate:CLLocationCoordinate2D){
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        let testquery = self.APIQuery(coordinate: coordinate)
        let url = URL(string: self.APIaddress + testquery + self.APIToken)
        print(url)
        let task = URLSession.shared.dataTask(with: url!){
            (data,response,error) in
            if error != nil{
                print("Error \(String(describing: error))")
                return
            }else{
                guard let data = data else{return}
                do{
                    print(data)
                    var parkingSpot: [Parking] = []
                    
                    parkingSpot = try JSONDecoder().decode([Parking].self, from: data)
                    var parkingspotList : [AccessibleFacilities] = []
                    for spot in parkingSpot{
                        var park = AccessibleFacilities()
                        park.type = AccessibleFacilityType.parkingSpot
                        park.category = "Parking Spot"
                        park.latitude = Double(spot.lat!)
                        park.longitude = Double(spot.lon!)
                        parkingspotList.append(park)
                    }
                    self.parkingspots = parkingspotList
                    print(self.parkingspots.count)

                    DispatchQueue.main.async { // Correct
                        self.activityIndicator.stopAnimating()
                        UIApplication.shared.endIgnoringInteractionEvents()
                        self.MapView.addAnnotations(self.parkingspots)
                    }
                    

                }catch let jsonErr{
                    print("Error serializing json",jsonErr)
                }
            }
        }
        task.resume()
    }

}




