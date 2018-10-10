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
import AVFoundation

protocol searchForDestination {
    func searchforDestination(destination:MKMapItem?, startPoint:MKMapItem?, nearestDestination:String?)
}

class MapViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate, searchForDestination {

    var functionList = ["Public Toilets", "Water Fountains","Accessible Building","Nearby"]
    
    @IBOutlet weak var MapView: MKMapView!

    //location Manager
    let manager = CLLocationManager()
    
    // all the annotations in the map including public toilet, accessible buildings and water fountains
    var annotationList : [AccessibleFacilities] = []
    
    //user location
    var userLocation : CLLocation?
    
    //default distance, the circle around the user
    let defaultdistance = 0.5
    
    //start
    var forsegmentControlStartItem: MKMapItem?
    
    
    @IBOutlet weak var drawRouteButton: UIButton!
    
    
    var start = true
    
    //destination item for segmental Control
    var forsegmentControlDestinationItem : MKMapItem?
    
    // all the coordinates along with the selected route
    var coords: [CLLocationCoordinate2D] = []
    
    @IBOutlet weak var transportControl: UISegmentedControl!
    
    @IBOutlet weak var locateMe: UIButton!
    
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var DistanceLabel: UILabel!
    
    @IBOutlet weak var InstructionLabel: UILabel!
    
    @IBOutlet weak var navigationView: UIView!
    
    //start item, MKMapItem
    var startItem : MKMapItem?
    
    //The annotation of start item
    var startAnnotation : CustomPointAnnotation?
    
    // destinationItem,
    var destinationItem : MKMapItem?
    
    // the annotation of the selected annotation
    var destinationAnnotation: CustomPointAnnotation?
    
    //selected route after the navigation started
    var route:MKRoute?
    
    //the annotations along with the route
    var alongWithTheRoute : [AccessibleFacilities] = []
    
    //the steps of the route
    var routeSteps : [MKRouteStep] = []
    
    //to check internet connection
    var reachability : Reachability?
    
    //database
    var databaseRef : DatabaseReference?
    
    //the list of public toilets
    var publicToiletList : [AccessibleFacilities] = []
    
    // the list of water fountains
    var waterFountainList : [AccessibleFacilities] = []
    
//    // the list of accessibuildings
//    var accessibleBuildingList : [AccessibleFacilities] = []
    
    //list just to store toilets and water fountains
    var publicToiltToiletAnnotationList: [AccessibleFacilities] = []
    
    // parking spots
    var parkingspots: [AccessibleFacilities] = []
    
    
    let activityIndicator = UIActivityIndicatorView()
    
    // steepness List
    var steepnessList:[Steepness] = []
    
    @IBOutlet weak var buttonControl: UIButton!
    
    var buttonControlSelected = false
    
    @IBOutlet weak var nearbyButton: UIButton!
    
    @IBOutlet weak var toiletButton: UIButton!
    
    @IBOutlet weak var waterButton: UIButton!
    
    @IBOutlet weak var parkButton: UIButton!
    
    @IBOutlet weak var functionView: UIView!
    
    //
    var synthesizer: AVSpeechSynthesizer?
    
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var totalDistanceLabel: UILabel!
    
    @IBOutlet weak var arrivalTimeLabel: UILabel!
    
    @IBOutlet weak var newlayout: NSLayoutConstraint!
    
    var polgons : [customPolygon] = []
    
    var purplePolgonsView:MKPolygonRenderer?

    var fakelocation = CLLocationCoordinate2DMake(-37.806635, 144.960919)
    
    
    var navigationButtonClicked = false{
        didSet{
            if navigationButtonClicked == true {
                self.drawRouteButton.setImage(#imageLiteral(resourceName: "clear-76"), for: .normal)
                self.buttonControl.isHidden = true
            }else{
                
                self.drawRouteButton.setImage(#imageLiteral(resourceName: "navigation-76"), for: .normal)
                self.buttonControl.isHidden = false
            }
        }
    }
    
    var nearbyClicked = false {
        didSet{
            if nearbyClicked == true{
            setFunctionButtonImage()
            nearbyButton.setImage(#imageLiteral(resourceName: "nearbyblue-76"), for: .normal)
            }
        }
    }
    
    var toiletClicked = false{
        didSet{
            if toiletClicked == true{
                setFunctionButtonImage()
                toiletButton.setImage(#imageLiteral(resourceName: "toilet-76"), for: .normal)
            }
        }
    }
    
    var parkClicked = false{
        didSet{

            if parkClicked == true{
                setFunctionButtonImage()
                parkButton.setImage(#imageLiteral(resourceName: "parking-76"), for: .normal)
            }

        }
    }
    
    var waterClicked = false{
        didSet{
            if waterClicked == true {
                setFunctionButtonImage()
                waterButton.setImage(#imageLiteral(resourceName: "water-76"), for: .normal)
            }
        }
    }
    
    func setupButtons()  {
        self.MapView.subviews[1].removeFromSuperview()
        
        drawRouteButton.setImage(#imageLiteral(resourceName: "navigation-76"), for: .normal)
        drawRouteButton.frame = CGRect(x: 246, y: 494, width: 70, height: 70)
        drawRouteButton.layer.cornerRadius = 0.5 * drawRouteButton.bounds.size.width
        drawRouteButton.clipsToBounds = true
        drawRouteButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        drawRouteButton.layer.shadowRadius = 5
        drawRouteButton.layer.shadowOpacity = 0.3
//        drawRouteButton.backgroundColor = UIColor.black
        
        locateMe.setImage(#imageLiteral(resourceName: "target-1-76"), for: .normal)
        locateMe.frame = CGRect(x: 246, y: 420, width: 70, height: 70)
        locateMe.layer.cornerRadius = 0.5 * locateMe.bounds.size.width
        locateMe.clipsToBounds = true
        locateMe.layer.shadowOffset = CGSize(width: 0, height: 10)
        locateMe.layer.shadowRadius = 5
        locateMe.layer.shadowOpacity = 0.3
//        locateMe.backgroundColor = UIColor.black
        
        startButton.setImage(#imageLiteral(resourceName: "start-76"), for: .normal)
        startButton.frame = CGRect(x: 246, y: 346, width: 70, height: 70)
        startButton.layer.cornerRadius = 0.5 * startButton.bounds.size.width
        startButton.clipsToBounds = true
        startButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        startButton.layer.shadowRadius = 5
        startButton.layer.shadowOpacity = 0.3
//        startButton.backgroundColor = UIColor.black
        
        buttonControl.setImage(#imageLiteral(resourceName: "open-76"), for: .normal)
        buttonControl.frame = CGRect(x: 8, y: 494, width: 70, height: 70)
        buttonControl.layer.cornerRadius = 0.5 * buttonControl.bounds.size.width
        buttonControl.clipsToBounds = true
        buttonControl.layer.shadowOffset = CGSize(width: 0, height: 10)
        buttonControl.layer.shadowRadius = 5
        buttonControl.layer.shadowOpacity = 0.3
//        buttonControl.backgroundColor = UIColor.black
        

        self.setFunctionButtonImage()
        nearbyButton.frame = CGRect(x: 0, y: 140, width: 70, height: 70)
        nearbyButton.layer.cornerRadius = 0.5 * nearbyButton.bounds.size.width
        nearbyButton.clipsToBounds = true
        nearbyButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        nearbyButton.layer.shadowRadius = 5
        nearbyButton.layer.shadowOpacity = 0.3
        
        
        toiletButton.frame = CGRect(x: 0, y: 70, width: 70, height: 70)
        toiletButton.layer.cornerRadius = 0.5 * toiletButton.bounds.size.width
        toiletButton.clipsToBounds = true
        toiletButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        toiletButton.layer.shadowRadius = 5
        toiletButton.layer.shadowOpacity = 0.3
        
        
        
       
        waterButton.frame = CGRect(x: 0, y: 70, width: 70, height: 70)
        waterButton.layer.cornerRadius = 0.5 * waterButton.bounds.size.width
        waterButton.clipsToBounds = true
        waterButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        waterButton.layer.shadowRadius = 5
        waterButton.layer.shadowOpacity = 0.3
        
        
        
        parkButton.frame = CGRect(x: 0, y: 210, width: 70, height: 70)
        parkButton.layer.cornerRadius = 0.5 * parkButton.bounds.size.width
        parkButton.clipsToBounds = true
        parkButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        parkButton.layer.shadowRadius = 5
        parkButton.layer.shadowOpacity = 0.3
        
        
        
    }
    
    func setFunctionButtonImage(){
        nearbyButton.setImage(#imageLiteral(resourceName: "nearby black-76"), for: .normal)
        toiletButton.setImage(#imageLiteral(resourceName: "toilet black-76"), for: .normal)
        waterButton.setImage(#imageLiteral(resourceName: "water black-76"), for: .normal)
        parkButton.setImage(#imageLiteral(resourceName: "parking black-76"), for: .normal)
    }
    
    override func viewDidLoad() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge], completionHandler: {
            didAllow,error in
        })
        self.reachability = Reachability.init()
        
        setupButtons()
        super.viewDidLoad()
        //set navigation view(subview)
        self.navigationView.isHidden = true
        self.navigationView.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        self.navigationView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.7018407534)
        
        //set up Mapview
        MapView.delegate = self
        
        MapView.showsCompass = false
        
        MapView.showsBuildings = false
        MapView.showsUserLocation = true
        MapView.showsPointsOfInterest = false
        MapView.mapType = MKMapType.standard
        MapView.setUserTrackingMode(.followWithHeading, animated: true)
        
        //setup transportControl
        self.transportControl.setEnabled(false, forSegmentAt: 0)
        self.transportControl.setEnabled(false, forSegmentAt: 1)
        self.transportControl.isHidden = true
        self.transportControl.layer.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.startButton.isHidden = true
        
        // initialize the synthesizer
        synthesizer = AVSpeechSynthesizer()
        
        //set up location manager
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        //ask for permission
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
        // if the list is empty load data from database
        if self.publicToiletList.count == 0 {
            // check internet connection
        if ((self.reachability!.connection) == .cellular || (self.reachability!.connection == .wifi)){
            UIApplication.shared.beginIgnoringInteractionEvents()
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
            activityIndicator.center = self.view.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.startAnimating()
            self.view.addSubview(activityIndicator)
            
            //require data from database
            databaseRef = Database.database().reference()
            getPublicToiletsData()
            getWaterFountainData()
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
    
    
    var zoomedin = false
    //https://www.hackingwithswift.com/example-code/system/how-to-run-code-after-a-delay-using-asyncafter-and-perform
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {

        MapView.setUserTrackingMode(.followWithHeading, animated: true)
        if zoomedin == false{

            locateMe(self)
            MapView.setUserTrackingMode(.followWithHeading, animated: true)
            zoomedin = true
            MapView.isScrollEnabled = false
        }

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
                let publicToilet = AccessibleFacilities()
                publicToilet.id = (item as! String)
                publicToilet.category = toiletInfo.object(forKey: "Category") as? String
                publicToilet.detail = toiletInfo.object(forKey: "Details") as? String
                publicToilet.desc = toiletInfo.object(forKey: "Description") as? String
                publicToilet.disableFlag = toiletInfo.object(forKey: "DisableFlag") as? String
                if publicToilet.disableFlag == "Yes"{
                    publicToilet.type = AccessibleFacilityType.accessiblePublicToilet
                }else{
                    publicToilet.type = AccessibleFacilityType.inaccessiblePublicToilet
                }
                publicToilet.latitude = toiletInfo.object(forKey: "Latitude") as? Double
                publicToilet.longitude = toiletInfo.object(forKey: "Longitude") as? Double

                self.publicToiletList.append(publicToilet)
            }
            self.annotationList.append(contentsOf: self.publicToiletList)
            
            self.publicToiltToiletAnnotationList.append(contentsOf: self.publicToiletList)
            
            self.nearbyButtonClicked(self)
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
                let waterFountain = AccessibleFacilities()
                waterFountain.id = item as? String
                waterFountain.type = AccessibleFacilityType.waterFountain
                waterFountain.desc = waterInfo.object(forKey: "Description") as? String
                waterFountain.detail = waterInfo.object(forKey: "Details") as? String
                waterFountain.category = waterInfo.object(forKey: "Category") as? String
                waterFountain.disableFlag = waterInfo.object(forKey: "DisableFlag") as? String
                waterFountain.latitude = waterInfo.object(forKey: "Latitude") as? Double
                waterFountain.longitude = waterInfo.object(forKey: "Longitude") as? Double
                self.waterFountainList.append(waterFountain)
            }
            self.annotationList.append(contentsOf: self.waterFountainList)
            self.publicToiltToiletAnnotationList.append(contentsOf: self.waterFountainList)
            self.nearbyButtonClicked(self)
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
                steepness.key = item as! String
                steepness.steepnessFlag = steepInfo.object(forKey: "SteepFlag") as! Int
                steepness.coordinates = steepInfo.object(forKey: "coordinates") as! [[[[Double]]]]
                self.steepnessList.append(steepness)
            }
            var polygonarray : [customPolygon] = []
            for item in self.steepnessList{
                polygonarray.append(self.drawShap(coornidatesArray: self.changeArrayToCoornidates(points: item.coordinates), steepnessLevel: item.steepnessFlag, identifier: item.key))
                
            }
            self.polgons = polygonarray
            self.MapView.addOverlays(self.polgons)
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()

        })
    }
    
    
    
    //change Double arrary to coordinates to draw the polygon
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
    //put a shap on the map
    func drawShap(coornidatesArray:[CLLocationCoordinate2D],steepnessLevel: Int, identifier: String) -> customPolygon{
        let polygon = customPolygon(coordinates: coornidatesArray, count: coornidatesArray.count)
        polygon.colorLevel = steepnessLevel
        return polygon
    }
    
    
    //reference from: TANDm
    //register annotationView class
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
        // remove the previous circle
        for item in MapView.overlays{
            if item.title == "location circle"{
                MapView.remove(item)
            }
        }
        userLocation = location

        // add a circle to the user's current location
        
        let rad = CLLocationDistance(500)
        let newCircle = MKCircle(center: CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), radius: rad)
        newCircle.title = "location circle"
        MapView.add(newCircle)
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //remove all the notification
        removeNotification()
        //show buttonControl and hide the transport Control
        self.buttonControl.isHidden = false
        self.transportControl.setEnabled(false, forSegmentAt: 0)
        self.transportControl.setEnabled(false, forSegmentAt: 1)
        self.transportControl.isHidden = true
        if buttonControlSelected == true{
            functionListButtonClicked(self)
        }
        manager.stopUpdatingHeading()
        
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
        
        if self.navigationButtonClicked == true{
            self.navigationButtonClicked = false
        }
        
        if self.transportControl.isHidden == false{
            self.transportControl.isHidden = true
        }
        
        let destinationPlacemarker = MKPlacemark(coordinate: (view.annotation?.coordinate)! )
        
        self.destinationItem = MKMapItem(placemark: destinationPlacemarker)
        
        if self.destinationAnnotation != nil{
            if !(view.annotation is CustomPointAnnotation){
            self.MapView.removeAnnotation(self.destinationAnnotation!)
            }
        }
        
        let span:MKCoordinateSpan?
        
        //parking spot different span
        if view.annotation?.title == "Parking Spot"{
            span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
            let region = MKCoordinateRegion(center: (self.destinationItem?.placemark.coordinate)!, span: span!)
            mapView.setRegion(region, animated: false)
        }else{
        span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        }
//        let region = MKCoordinateRegion(center: (self.destinationItem?.placemark.coordinate)!, span: span!)
//        mapView.setRegion(region, animated: false)
    }
    
    
    // add anotation in the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        guard let facilityannotation = annotation as?  AccessibleFacilities else {
            //register custom annotation
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
        
        // cluster annotation 
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
    
    //
    @IBAction func navigationButtonClicked(_ sender: Any) {
        //check internet connection
        if ((self.reachability!.connection) == .cellular || (self.reachability!.connection == .wifi)){
            if self.destinationItem == nil{
                displayErrorMessage(title: "No destination", message: "Sorry please select a destination first.")
            }else{
                if self.navigationButtonClicked == false{
                    var newDestination = CustomPointAnnotation()
                    
                    if self.MapView.selectedAnnotations.first != nil{
                    newDestination = self.addSearchItem(mapItem: destinationItem!, imageName: "pin-end 3-40")
                    
                   
                    if self.MapView.selectedAnnotations.first?.title != nil{
                        newDestination.title = (self.MapView.selectedAnnotations.first?.title)!
                    }
                    if self.MapView.selectedAnnotations.first?.subtitle != nil{
                        newDestination.subtitle = (self.MapView.selectedAnnotations.first?.subtitle)!
                    }
                        
                    }else{
                        newDestination = self.destinationAnnotation!
                    }
                    
                    if self.destinationAnnotation != nil{
                        self.MapView.removeAnnotation(self.destinationAnnotation!)
                    }
                    
                    self.destinationAnnotation = newDestination
                    self.MapView.addAnnotation(self.destinationAnnotation!)
                    //select destination annotation
                    self.MapView.selectAnnotation(self.destinationAnnotation!, animated: true)
                    //setup start item
                    if startItem == nil{
                        if userLocation != nil{
                            let sourcePlacemark = MKPlacemark(coordinate: (self.userLocation?.coordinate)!)
                            let sourceItem = MKMapItem(placemark: sourcePlacemark)
                            self.drawRoute(startItem: sourceItem, destinationItem: destinationItem!)
                        }else{
                            locationServiceIsNotGivenErrorMessage()
                        }
                    }else{
                        self.drawRoute(startItem: self.startItem!, destinationItem: destinationItem!)
                    }
                }else{
                    let polyline = self.MapView.overlays.filter{$0 is MKPolyline}
                    self.MapView.removeOverlays(polyline)
                    
                    if self.destinationAnnotation != nil{
                        self.MapView.removeAnnotation(self.destinationAnnotation!)
                    }
                    
                    if self.destinationItem != nil{
                        self.destinationItem = nil
                    }
                    
                    if self.startAnnotation != nil{
                        self.MapView.removeAnnotation(self.startAnnotation!)
                    }
                    
                    if self.startItem != nil{
                        self.startItem = nil
                    }
                    
                    self.transportControl.isHidden = true
                    self.transportControl.setEnabled(false, forSegmentAt: 0)
                    self.transportControl.setEnabled(false, forSegmentAt: 1)
                    self.navigationButtonClicked = false
                    self.startButton.isHidden = true
                }
            }
        }else{

              displayErrorMessage(title: "Error", message: "No internet Connection")
        }
    }
    

    //draw route on the map
    func drawRoute(startItem: MKMapItem, destinationItem:MKMapItem){
        
        for overlay in self.MapView.overlays{
            if overlay is MKPolyline{
                self.MapView.remove(overlay)
            }
        }
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        UIApplication.shared.beginIgnoringInteractionEvents()
        // remove notification
        removeNotification()
        //set the buttoncontrol and transport control
        
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
        //set the transportControl
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
        //caulculate route
        directions.calculate(completionHandler: { (response, error) in
            guard let response = response else{
                if let error = error{
                    self.activityIndicator.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                    self.buttonControl.isHidden = false
                    self.transportControl.isHidden = true
                    self.transportControl.setEnabled(false, forSegmentAt: 0)
                    self.transportControl.setEnabled(false, forSegmentAt: 1)
                    print(error)
                    //https://stackoverflow.com/questions/28152526/how-do-i-open-phone-settings-when-a-button-is-clicked
                    let alertView = UIAlertController(title: "Error ", message: "No route found", preferredStyle: .alert)
                    alertView.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { action in
                        print(" no is clicked")
                        
                    }))
                    self.present(alertView, animated: false, completion: nil)
                }
                return
            }
            self.navigationButtonClicked = true
            if self.userLocation != nil{
                
                if self.startItem == nil{
                    self.startButton.isHidden = false
                }
            }
            let routes = response.routes
            
            let item = routes.first!
            self.route = item
            self.routeSteps = item.steps
            item.polyline.title = startItem.name! + " to " + destinationItem.name!
            item.polyline.subtitle = "\(item.distance)"
            //get all the coords from the polyline
            let coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: item.polyline.pointCount)
            item.polyline.getCoordinates(coordsPointer, range: NSMakeRange(0, item.polyline.pointCount))
            
            //remove the coords if it is not empty
            if self.coords.count != 0 {
                self.coords.removeAll()
            }
            for i in 0..<item.polyline.pointCount {
                self.coords.append(coordsPointer[i])
            }
            //remove all the annotation in the along with route in the map
            self.MapView.removeAnnotations(self.alongWithTheRoute)
            var annotationList : [AccessibleFacilities] = []

            // get the nearby facility of the route
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
            
            // remove the annotation in the list
            self.alongWithTheRoute.removeAll()
            self.alongWithTheRoute.append(contentsOf: annotationList)
            //put the along with route annotations on the map
            self.MapView.addAnnotations(self.alongWithTheRoute)
            self.MapView.add(item.polyline, level:.aboveRoads )
            
            
            let rekt = item.polyline.boundingMapRect
            let  newSize = MKMapSize(width: (rekt.size.width) , height: (rekt.size.height ))
            let newReke = MKMapRect(origin: rekt.origin , size: newSize)
                self.MapView.setRegion(MKCoordinateRegionForMapRect(newReke), animated: false)
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            if directionRequest.transportType == .walking{
                let evaluationArray = self.evaluteTheAverageSteepnessOfTheRoad(coordinatesArray: self.coords)
                var errorMessage = ""
                let totalSteepnessLevel = evaluationArray.reduce(0,+)
                let highest = evaluationArray.max()
                let average = Double(totalSteepnessLevel)/Double(evaluationArray.count)
                if highest! >= 1  {
                    errorMessage.append("The route might be a little bit steep for you.")
                }else{
                    errorMessage.append("The route is not steep.")
                }

                if routes[0].distance > 2500 {
                    errorMessage.append("\n It might be too far for you, please try other ways to commute")
                }
                self.displayErrorMessage(title: "Trip Evaluation", message: errorMessage)
            }
        })
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline{
            //add MKPolyline
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        renderer.lineWidth = 5.0
        return renderer
        }else if overlay is MKCircle{
            //add MKCircle
            let circleView = MKCircleRenderer(overlay: overlay)
            circleView.strokeColor = UIColor.clear
            if overlay.title == "location circle"{
            circleView.fillColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 0.2004762414)
            }else{
                circleView.fillColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 0.2958315497)
            }
            return circleView
       }
            else if overlay is MKPolygon{
            //set color for polygon
            let polygon = overlay as! customPolygon

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
    
    //locate a specific location
    func locateLocation(location: CLLocation) {
        let span = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), span: span)
        MapView.setRegion(region, animated: true)
    }
    
    // locate current user location, cancel the start item
    @IBAction func locateMe(_ sender: Any) {

        if userLocation == nil{
            locationServiceIsNotGivenErrorMessage()
        }else{
        MapView.setUserTrackingMode(.followWithHeading, animated: true)
        locateLocation(location: userLocation!)
        }
    }
    
    //get user's nearby facilities
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
    
    // get all the nearby facilities around a given annotation with a specific range
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
        return nearbyAnnotation
    }
    
    //display error message
    func displayErrorMessage(title:String, message: String){
        let alertview = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertview.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        func dismissErrorMessage(){
            alertview.dismiss(animated: true, completion: nil)
        }
        

        self.present(alertview, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // change 2 to desired number of seconds
            alertview.dismiss(animated: true, completion: nil)
        }
       
    }
    
    // if both user location and start item are nil, the function of turning to another page, should be negative
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if self.userLocation != nil || self.startItem != nil{
            self.performSegue(withIdentifier: "showInformation", sender: self)
        }else{
            locationServiceIsNotGivenErrorMessage()
        }
    }
    //add search item on the map with a specific icon
    func addSearchItem(mapItem: MKMapItem,imageName: String) -> CustomPointAnnotation{
        let newFacility = CustomPointAnnotation()
        newFacility.title = mapItem.placemark.name
        newFacility.subtitle = mapItem.placemark.title
        newFacility.imageName = imageName
        newFacility.coordinate = mapItem.placemark.coordinate
//        self.MapView.addAnnotation(newFacility)
        return newFacility
    }
    
    //change the transport type
    @IBAction func functionIsChanged(_ sender: Any) {
        if self.start == false{
            self.startIsClicked(self)
        }
        self.drawRoute(startItem: self.forsegmentControlStartItem!, destinationItem: self.forsegmentControlDestinationItem!)
    }
    
    var steepnessTimer = Timer()
    //start turn by turn navigation
    @IBAction func startIsClicked(_ sender: Any) {

        if start == true{
            UIApplication.shared.beginIgnoringInteractionEvents()
            //hide navigation bar
            hideNavigationBar(show: true)
            self.manager.startUpdatingHeading()
            self.navigationView.isHidden = false
            self.drawRouteButton.isHidden = true
            self.MapView.deselectAnnotation(self.destinationAnnotation, animated: false)
            //set text notification
           self.DistanceLabel.text = "\((self.routeSteps[1].distance)) m "
            
            if self.routeSteps.first?.instructions == ""{
                self.InstructionLabel.text = self.routeSteps[1].instructions
            }else{
                self.InstructionLabel.text = "\(Int((self.routeSteps.first?.instructions)!)!)"
            }
            durationLabel.text = self.secondsToHoursMinutes(seconds: Int((self.route?.expectedTravelTime)!))
            let distance = Int((self.route?.distance)!)
            if distance > 1000{
                self.totalDistanceLabel.text = "\(distance/1000) km"
            }else{
                self.totalDistanceLabel.text = "\(Int(distance)) m"
            }
            arrivalTimeLabel.text = "\(self.convertDateToString(duration: (self.route?.expectedTravelTime)!)) arrival"
            //set voice navigation
           self.voiceGuide(message: startMessage(distance: (self.route?.distance)!, arrivingTime: self.convertDateToString(duration: (self.route?.expectedTravelTime)!), duration: self.secondsToHoursMinutes(seconds: Int((self.route?.expectedTravelTime)!))))
            start = false
            
            self.startButton.setImage(#imageLiteral(resourceName: "stop-76"), for: .normal)
            newlayout.constant = newlayout.constant - 150
            DispatchQueue.main.async { // change 2 to desired number of seconds
                for step in self.routeSteps{
                    self.addnotificationToStep(step: step)
                }
            }
            
            MapView.isZoomEnabled = false
            if self.transportControl.selectedSegmentIndex == 0{

            steepnessTimer = Timer.scheduledTimer(
                timeInterval: 30.0,
                target: self,
                selector: #selector(self.checkUserInSteepNessRegion),
                userInfo: nil,
                repeats: true
            )
//                print(steepnessTimer.isValid)
            }
            
            self.startButton.isEnabled = false
            Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.setStartButtonEnable), userInfo: nil, repeats: false)
            UIApplication.shared.endIgnoringInteractionEvents()
        }else{
//            if self.transportControl.selectedSegmentIndex == 0{
            if steepnessTimer != nil{
                steepnessTimer.invalidate()
            }
                print(steepnessTimer.isValid)
//            }
            if zoomedin == true{
                zoomedin = false
                MapView.isScrollEnabled = true
            }
            MapView.isZoomEnabled = true
            //stop voice navigation
            if (self.synthesizer?.isSpeaking)!{
                self.synthesizer?.stopSpeaking(at: .immediate)
            }
            
            if self.oldPolygon != nil{
                oldPolygon = nil
            }
            // show navigation bar
            self.drawRouteButton.isHidden = false
            hideNavigationBar(show: false)
            self.navigationView.isHidden = true
            start = true
            //change the image
            self.startButton.setImage(#imageLiteral(resourceName: "start-76"), for: .normal)
            self.manager.stopUpdatingHeading()
            self.locateLocation(location: self.userLocation!)
            newlayout.constant = newlayout.constant + 150
            //remove the notification
            removeNotification()
        }
    }
    
    
    @objc func setStartButtonEnable() {
        self.startButton.isEnabled = true
    }
    //remove the notifications
    func removeNotification() {
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
    
    //prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showInformation"{
            let controller = segue.destination as! InformationViewController
            if self.startItem == nil{
                controller.userLocation = self.userLocation
                
            }else{
                controller.userLocation = CLLocation(latitude: (self.startItem?.placemark.coordinate.latitude)!, longitude: (self.startItem?.placemark.coordinate.longitude)!)
            }
            controller.destination = CLLocation(latitude: (self.destinationItem?.placemark.coordinate.latitude)!, longitude: (self.destinationItem?.placemark.coordinate.longitude)!)
            controller.hiddenMessage = self.MapView.selectedAnnotations[0].title!
            guard let annotation = self.MapView.selectedAnnotations[0] as? AccessibleFacilities else{
                return
            }
            if annotation.detail != nil{
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
        let coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: step.polyline.pointCount)
        step.polyline.getCoordinates(coordsPointer, range: NSMakeRange(0, step.polyline.pointCount))
        var stepCount : [CLLocationCoordinate2D] = []
        for i in 0 ..< step.polyline.pointCount{
            stepCount.append(coordsPointer[i])
        }
        if stepCount.count == 1 {
        }else{
            addNotificationToAPoint(center: stepCount.first!, radius: 20,  identifier: step.instructions)
            }
        
        // add the notification to the last spot
        if step == self.routeSteps.last{
            addNotificationToAPoint(center: stepCount.last!, radius: 20,identifier: "Destination")
        }
    }
    
    // add notification to a specific point
    func addNotificationToAPoint(center: CLLocationCoordinate2D, radius: Int, identifier: String) {
        let circle = MKCircle(center: center, radius: CLLocationDistance(radius))
        self.MapView.add(circle)
        let notificationRegion = CLCircularRegion(center: center, radius: CLLocationDistance(radius), identifier: identifier)
        notificationRegion.notifyOnEntry = true
        notificationRegion.notifyOnExit = true
        self.manager.startMonitoring(for: notificationRegion)
//        print(self.MapView.)
    }

     // when user entered the region. the Distance lable and Instruction Label will be changed with it.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print(region.identifier)
        let step = findstepByRegion(identifier: region.identifier)
        print(step.distance)
        let distance = Int(step.distance)
        if distance > 1000 {
            self.DistanceLabel.text = "\(distance/1000) km"
        }else{
            self.DistanceLabel.text = "\(Int(distance)) m"
        }
        self.InstructionLabel.text = region.identifier
        if step == self.routeSteps.last{
            
            self.voiceGuide(message: self.destinationMessage())
        }else{
            self.voiceGuide(message: self.stepMessage(step:step ))
        }
        pushNotification(step: step)
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
    
    
    //function list control
    @IBAction func functionListButtonClicked(_ sender: Any) {
        
        if buttonControlSelected == false{
            self.functionView.isHidden = false
            self.buttonControl.setImage(#imageLiteral(resourceName: "close 2-76"), for: .normal)
            buttonControlSelected = true
        }else{
            self.functionView.isHidden = true
            self.buttonControl.setImage(#imageLiteral(resourceName: "open-76"), for: .normal)
            buttonControlSelected = false
        }
    }
    
    //nearbyButton
    @IBAction func nearbyButtonClicked(_ sender: Any) {
        let removedAnnotations = self.MapView.annotations.filter{$0 is AccessibleFacilities}
        self.MapView.removeAnnotations(removedAnnotations)
//        self.destinationItem = nil
//        self.destinationAnnotation = nil
        self.nearbyClicked = true
        self.toiletClicked = false
        self.waterClicked = false
        self.parkClicked = false
        if buttonControlSelected == true{
            functionListButtonClicked(self)
        }
        self.MapView.addAnnotations(self.getNearbyFacilities())
        if self.userLocation != nil{
            locateLocation(location: userLocation!)
        }else{
            locationServiceIsNotGivenErrorMessage()
        }
    }

    
    //toilet button
    @IBAction func toiletButtonIsClicked(_ sender: Any) {
        let removedAnnotations = self.MapView.annotations.filter{$0 is AccessibleFacilities}
        self.MapView.removeAnnotations(removedAnnotations)
        self.nearbyClicked = false
        self.toiletClicked = true
        self.waterClicked = false
        self.parkClicked = false
        if buttonControlSelected == true{
            functionListButtonClicked(self)
        }
//        self.destinationItem = nil
//        self.destinationAnnotation = nil
        self.MapView.addAnnotations(self.publicToiletList)
        
    }
    
    //water Button
    @IBAction func waterButtonIsClicked(_ sender: Any) {
        let removedAnnotations = self.MapView.annotations.filter{$0 is AccessibleFacilities}
        self.MapView.removeAnnotations(removedAnnotations)
        self.nearbyClicked = false
        self.toiletClicked = false
        self.waterClicked = true
        self.parkClicked = false
        if buttonControlSelected == true{
            functionListButtonClicked(self)
        }

        self.MapView.addAnnotations(self.waterFountainList)
    }
    
    //park Button
    @IBAction func parkButtonClicked(_ sender: Any) {
        let removedAnnotations = self.MapView.annotations.filter{$0 is AccessibleFacilities}
        self.MapView.removeAnnotations(removedAnnotations)
        if buttonControlSelected == true{
            functionListButtonClicked(self)
        }
        self.nearbyClicked = false
        self.toiletClicked = false
        self.waterClicked = false
        self.parkClicked = true
        if userLocation != nil{
        getAvailableParkingSpot(coordinate: (userLocation?.coordinate)!)
        }else{
            self.locationServiceIsNotGivenErrorMessage()
        }
    }
    
    //search for a location from the protocol
    func searchforDestination(destination: MKMapItem?, startPoint: MKMapItem?, nearestDestination:String?) {
        self.nearbyButtonClicked(self)
        
        if self.destinationAnnotation != nil{
        self.MapView.removeAnnotation(self.destinationAnnotation!)
        }
        if self.startAnnotation != nil{
            self.MapView.removeAnnotation(self.startAnnotation!)
        }
        
        if startPoint != nil{
            self.startItem = startPoint
            if destination != nil{
                self.destinationItem = destination
                startAnnotation = addSearchItem(mapItem: self.startItem!,imageName: "pin-start 3-40")
                self.MapView.addAnnotation(startAnnotation!)
                self.getAvailableParkingSpot(coordinate: (self.destinationItem?.placemark.coordinate)!)
                checkCoordinateInTheAccessibleBuilding(MapItem: destination!)
            }else{
                if nearestDestination! == "Nearest Public Toilet"{
                    
                    let targetAnnotation = self.getNearestToilet(coordinate: (self.startItem?.placemark.coordinate)!)
                    let destinationPlaceMark = MKPlacemark(coordinate: (targetAnnotation!.coordinate))
                    self.destinationItem = MKMapItem(placemark: destinationPlaceMark)
                    destinationAnnotation = addSearchItem(mapItem: self.destinationItem!, imageName: "pin-end 3-40")
                    destinationAnnotation?.title = targetAnnotation?.title
                    destinationAnnotation?.subtitle = targetAnnotation?.subtitle
                    self.MapView.addAnnotation(self.destinationAnnotation!)
                    
                }else if nearestDestination! ==  "Nearest Water Fountain"{
                    let targetAnnotation = self.getNearestWaterFountain(coordinate: (self.startItem?.placemark.coordinate)!)
                    let destinationPlaceMark = MKPlacemark(coordinate: (targetAnnotation!.coordinate))
                    self.destinationItem = MKMapItem(placemark: destinationPlaceMark)
                    destinationAnnotation = addSearchItem(mapItem: self.destinationItem!, imageName: "pin-end 3-40")
                    destinationAnnotation?.title = targetAnnotation?.title
                    destinationAnnotation?.subtitle = targetAnnotation?.subtitle
                    self.MapView.addAnnotation(self.destinationAnnotation!)
                }
                startAnnotation = addSearchItem(mapItem: self.startItem!,imageName: "pin-start 3-40")
                self.MapView.addAnnotation(startAnnotation!)
                drawRoute(startItem: self.startItem!, destinationItem: self.destinationItem!)
            }
            
            if self.startButton.isHidden == false{
                self.startButton.isHidden = true
            }

        }else{
            if userLocation != nil{
                self.startItem = nil
                if destination != nil{
                    self.destinationItem = destination
                    self.getAvailableParkingSpot(coordinate: (self.destinationItem?.placemark.coordinate)!)
                    checkCoordinateInTheAccessibleBuilding(MapItem: destination!)
                    
                }else{
                    if nearestDestination! == "Nearest Public Toilet"{
                        
                        let targetAnnotation = self.getNearestToilet(coordinate: (userLocation!.coordinate))
                        let destinationPlaceMark = MKPlacemark(coordinate: (targetAnnotation!.coordinate))
                        self.destinationItem = MKMapItem(placemark: destinationPlaceMark)
                        destinationAnnotation = addSearchItem(mapItem: self.destinationItem!, imageName: "pin-end 3-40")
                        destinationAnnotation?.title = targetAnnotation?.title
                        destinationAnnotation?.subtitle = targetAnnotation?.subtitle
                        self.MapView.addAnnotation(self.destinationAnnotation!)
                        
                    }else if nearestDestination! ==  "Nearest Water Fountain"{
                        
                        let targetAnnotation = self.getNearestWaterFountain(coordinate: (userLocation!.coordinate))
                        let destinationPlaceMark = MKPlacemark(coordinate: (targetAnnotation!.coordinate))
                        self.destinationItem = MKMapItem(placemark: destinationPlaceMark)
                        destinationAnnotation = addSearchItem(mapItem: self.destinationItem!, imageName: "pin-end 3-40")
                        destinationAnnotation?.title = targetAnnotation?.title
                        destinationAnnotation?.subtitle = targetAnnotation?.subtitle
                        self.MapView.addAnnotation(self.destinationAnnotation!)
                        
                    }
                }
                if self.destinationAnnotation != nil{
                    self.MapView.selectAnnotation(destinationAnnotation!, animated: true)
                    MapView.addAnnotations(getNearbyFacilities())
                    if self.userLocation != nil{
                        drawRoute(startItem: self.changeLocationToMapItem(location: self.userLocation!), destinationItem: self.destinationItem!)
                    }

                }
            }else{
                locationServiceIsNotGivenErrorMessage()
            }
    }
    }
    
    
    
    //API Address
    let APIaddress = "https://data.melbourne.vic.gov.au/resource/dtpv-d4pf.json?status=Unoccupied&"
    //APIToken
    let APIToken = "&$$app_token=L91hFMhjcf0tTl6cVMT0jOoqD"
    
    //APIQuery
    func APIQuery(coordinate: CLLocationCoordinate2D)->String{
        return "$where=within_circle(location,\(coordinate.latitude),\(coordinate.longitude),500)"
    }
    
    //struct for the parking
    struct Parking:Decodable {
        let bay_id:String?
        let lat:String?
        let coordinates: [Double]?
        let lon:String?
        let st_marker_id:String?
        let status:String?
    }
    
    //get available parking spot
    func getAvailableParkingSpot(coordinate:CLLocationCoordinate2D){
        let testquery = self.APIQuery(coordinate: coordinate)
        let url = URL(string: self.APIaddress + testquery + self.APIToken)
        if ((self.reachability!.connection) == .cellular || (self.reachability!.connection == .wifi)){
            activityIndicator.startAnimating()
            self.view.addSubview(activityIndicator)
            UIApplication.shared.beginIgnoringInteractionEvents()
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
                        let park = AccessibleFacilities()
                        park.type = AccessibleFacilityType.parkingSpot
                        park.category = "Parking Spot"
                        park.latitude = Double(spot.lat!)
                        park.longitude = Double(spot.lon!)
                        parkingspotList.append(park)
                    }
                    self.parkingspots = parkingspotList
                    print(self.parkingspots.count)

                    DispatchQueue.main.async {
                        // add annotations on the map
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
        }else{
            displayErrorMessage(title: "Error", message: "No Internet Connection")
        }
    }

    //convert date to String
    func convertDateToString(duration: Double) -> String{
        let date = NSDate(timeIntervalSinceNow: duration)
        let dateFormatter = DateFormatter()
        if duration > 86400{
            dateFormatter.dateFormat = " dd MMM yyyy HH:mm"
        }else{
        dateFormatter.dateFormat = "HH:mm"
        }
        let string = dateFormatter.string(from: date as Date)
        return string
    }
    
    //change seconds to Days/hours/minutes
    func secondsToHoursMinutes (seconds : Int) -> String {
        if seconds > 86400{
            let days = seconds / 86400
            let hours = (seconds % 86400) / 3600
            return "\(days) days and \(hours) hours"
        }
        if seconds > 3600{
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return "\(hours) hours and \(minutes) minutes"
        }else{
            let mins = seconds / 60
            return "\(mins) minutes"
        }
    }
    
    //voice navigation
    func voiceGuide(message: String){
        let utterace = AVSpeechUtterance(string: message)
        utterace.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterace.rate = 0.5
        if synthesizer?.isSpeaking == true{
            synthesizer?.stopSpeaking(at: .immediate)
        }
        synthesizer?.speak(utterace)
    }
    
    //startMessage
    func startMessage(distance:Double, arrivingTime: String, duration:String) -> String{
        let message = "Start from current Location to \((destinationAnnotation?.title) ?? "destination"), the journey will take you \(duration ), and you would arrive there at \(arrivingTime )"
        return message
    }
    
    //message for every step
    func stepMessage(step:MKRouteStep) -> String{
        let message = "Continue \(step.distance) and \(step.instructions)"
        return message
    }
    
    //arrive the destination message
    func destinationMessage()->String{
        let message = "You arrived at the destination."
        return message
    }
    
    //store the annotations on the map
    var tempAnnotationList:[AccessibleFacilities] = []
    func hideNavigationBar(show:Bool){
        self.navigationController?.navigationBar.isHidden = show
        self.transportControl.isHidden = show
        self.locateMe.isHidden = show
        if show == true{
            if tempAnnotationList.count != 0{
            tempAnnotationList.removeAll()
            }
            for annotation in MapView.annotations{
                guard let item = annotation as? AccessibleFacilities else{
                    continue
                }
                tempAnnotationList.append(item)
            }
            
            DispatchQueue.main.async() {
                for item in self.tempAnnotationList{
                    if self.MapView.annotations.contains(where: {$0.coordinate.latitude == item.coordinate.latitude && $0.coordinate.longitude == item.coordinate.longitude}){
                        self.MapView.removeAnnotation(item)
                    }else{
                        print("something is going on")
                    }
                }
            }
            
        }else{
            MapView.addAnnotations(tempAnnotationList)

        }
    }
    
    // push background notification
    func pushNotification(step:MKRouteStep){
        
        let content = UNMutableNotificationContent()
        content.title = step.instructions
        if step.notice != nil{
            content.subtitle = step.notice!
        }
        content.body = self.stepMessage(step: step)
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: step.instructions, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    //get nearest toilet
    func getNearestToilet(coordinate: CLLocationCoordinate2D) -> AccessibleFacilities? {
        var distanceDictionary : [String:CLLocationDistance] = [:]
        let sourceLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        for toilet in self.publicToiletList{
            let target = CLLocation(latitude: toilet.coordinate.latitude, longitude: toilet.coordinate.longitude)
            let distance = sourceLocation.distance(from: target)
            distanceDictionary[toilet.id!] = distance
        }
        let nearest = distanceDictionary.min{a,b in a.value < b.value}
        let nearestToilet = self.publicToiletList.filter{$0.id == nearest?.key}
        return nearestToilet.first
    }
    
    //get nearest waterfountain
    func getNearestWaterFountain(coordinate: CLLocationCoordinate2D) -> AccessibleFacilities? {
        var distanceDictionary : [String:CLLocationDistance] = [:]
        let sourceLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        for toilet in self.waterFountainList{
            let target = CLLocation(latitude: toilet.coordinate.latitude, longitude: toilet.coordinate.longitude)
            let distance = sourceLocation.distance(from: target)
            distanceDictionary[toilet.id!] = distance
        }
        let nearest = distanceDictionary.min{a,b in a.value < b.value}
        let nearestWaterFountain = self.waterFountainList.filter{$0.id == nearest?.key}
        return nearestWaterFountain.first
    }
    
    
    //https://stackoverflow.com/questions/36016764/check-if-user-location-is-inside-a-shape
    //check wheather a coordinate is in the polygon
    func coordinateInsidePolygon(coordinate:CLLocationCoordinate2D) -> customPolygon? {
        
        var containsPoint: Bool = false
        let polygon = self.MapView.overlays.filter{$0 is MKPolygon} as! [customPolygon]
        for item in polygon{
            let polygonPath:CGMutablePath = CGMutablePath()
            let arrPoints = item.points()
            
            for i in 0..<item.pointCount{
                let point : MKMapPoint = arrPoints[i]
                let pointCoordinate = MKCoordinateForMapPoint(point)
                let polygonPoint = self.MapView.convert(pointCoordinate, toPointTo: self.MapView)
                if (i == 0){
                    polygonPath.move(to: CGPoint(x: polygonPoint.x, y: polygonPoint.y))
                }else{
                    polygonPath.addLine(to: CGPoint(x: polygonPoint.x, y: polygonPoint.y))
                }
            }
            let mapPointAsCGP:CGPoint = self.MapView.convert(coordinate, toPointTo: self.MapView)
            containsPoint =  polygonPath.contains(mapPointAsCGP)
            if containsPoint{
                return item
            }
        }
        return nil
    }
    
    //evaluate whether a set of coordinates are in the steep region
    func evaluteTheAverageSteepnessOfTheRoad(coordinatesArray:[CLLocationCoordinate2D]) -> [Int]{
        
        var polygonArray : [Int] = []
        for coordinate in coordinatesArray{
            let polygon = coordinateInsidePolygon(coordinate: coordinate)
            if polygon != nil{
                polygonArray.append((polygon?.colorLevel)!)
            }else{
                polygonArray.append(0)
            }
        }
        return polygonArray
    }
    
    
    func checkCoordinateInTheAccessibleBuilding(MapItem:MKMapItem){
        let index = MapItem.placemark.title?.index(of: ",")
        let accessibleBuildingsRef = databaseRef?.child(functionList[2]).queryOrdered(byChild: "Description").queryEqual(toValue: String((MapItem.placemark.title?.prefix(upTo: index!))!))
        var accessiblebuildings : [AccessibleFacilities] = []
        var targetBuilding : AccessibleFacilities?
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        UIApplication.shared.beginIgnoringInteractionEvents()
        accessibleBuildingsRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                self.destinationAnnotation = self.addSearchItem(mapItem: self.destinationItem!, imageName: "pin-end 3-40")
                self.MapView.addAnnotation(self.destinationAnnotation!)
                self.activityIndicator.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
                if self.startItem == nil{
                    if self.userLocation != nil{
                        self.drawRoute(startItem: self.changeLocationToMapItem(location: self.userLocation!), destinationItem: self.destinationItem!)
                    }
                }else{
                    self.drawRoute(startItem: self.startItem!, destinationItem: self.destinationItem!)
                }
                return
            }
            for item in value.allKeys{
                let buildingInfo = value.object(forKey: item) as! NSDictionary
                let building = AccessibleFacilities()
                building.type = AccessibleFacilityType.accessibleBuilding
                building.id = item as? String
                building.category = buildingInfo.object(forKey: "Category") as? String
                building.detail = buildingInfo.object(forKey: "Details") as? String
                building.desc = buildingInfo.object(forKey: "Description") as? String
                building.disableFlag = buildingInfo.object(forKey: "DisableFlag") as? String
                building.latitude = buildingInfo.object(forKey: "Latitude") as? Double
                building.longitude = buildingInfo.object(forKey: "Longitude") as? Double
                accessiblebuildings.append(building)

            }
            if accessiblebuildings.count > 0{
             targetBuilding = accessiblebuildings.first
            }

            self.MapView.addAnnotation(targetBuilding!)
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            let dictionary = ["title": targetBuilding?.title, "subtitle":targetBuilding?.subtitle]
            let destinationPlacemarker = MKPlacemark(coordinate: (targetBuilding!.coordinate), addressDictionary: dictionary)
            
            self.destinationItem = MKMapItem(placemark: destinationPlacemarker)
            if self.startItem == nil{
                if self.userLocation != nil{
                    self.drawRoute(startItem: self.changeLocationToMapItem(location: self.userLocation!), destinationItem: self.destinationItem!)
                }
            }else{
                self.drawRoute(startItem: self.startItem!, destinationItem: self.destinationItem!)
            }
            
        })
    }
    
    var oldPolygon : customPolygon?
    //check whether the user is inside the steep regionif it is error message will be shown and push the notification
    
   @objc func checkUserInSteepNessRegion(){
    
    let polygon = self.self.coordinateInsidePolygon(coordinate: (userLocation?.coordinate)!)
    var match = true
    
    if polygon == oldPolygon{
        
        match = true
        
    }else{
        match = false

    }

        if polygon != nil{
            if match == false{
                oldPolygon = polygon
                var steepnessLevel = ""
                switch polygon?.colorLevel{
                case 1:
                    steepnessLevel = "Low"
                case 2:
                    steepnessLevel = "Medium"
                case 3:
                    steepnessLevel = "High"
                default:
                    steepnessLevel = "None"
                }
            
                displayErrorMessage(title: "Watch Out", message: "You are in the steep region and steepness level is \(steepnessLevel)")
                voiceGuide(message: "You are in the steep region and steepness level is \(steepnessLevel)")
                let content = UNMutableNotificationContent()
                content.title = "Watch out"
                content.body = "You are in the steep region and steepness level is \(steepnessLevel)"
                content.badge = 1
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let request = UNNotificationRequest(identifier: steepnessLevel, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                oldPolygon = polygon
           }
        }else{
            if match == true{
                displayErrorMessage(title: "Don't worry", message: "The road is not steep")
                voiceGuide(message: "Don't woorry, the road is not steep")
                let content = UNMutableNotificationContent()
                content.title = "Don't worry"
                content.body = "The road is not steep"
                content.badge = 1
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let request = UNNotificationRequest(identifier: "Don't worry", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                oldPolygon = self.polgons.first
            }

    }
    }

}




