//
//  functionListController.swift
//  WheelPath
//
//  Created by Salamender Li on 3/9/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit
import MapKit
import Firebase


var functionList = ["Public Toilets", "Water Fountains","Accessible Building","Nearby"]

var toiletsAndWaterFountainList : [CustomPointAnnotation] = []

class MenuController: UIViewController,UISearchBarDelegate {
    
    
    var nearby = false
    
    var databaseRef : DatabaseReference?
    
    var publicToiletList : [PublicToilet] = []
    
    var waterFountainList : [WaterFountain] = []
    
    var accessibleBuildingList : [AccessibleBuildings] = []
    
    var reachability : Reachability?
    
    var annotationList : [CustomPointAnnotation] = []
    
    let activityIndicator = UIActivityIndicatorView()

//    @IBOutlet weak var searchView: UIView!
    


    override func viewDidLoad() {
        super.viewDidLoad()

        self.reachability = Reachability.init()
        if ((self.reachability!.connection) == .cellular || (self.reachability!.connection == .wifi)){
            print(reachability!.connection)
            databaseRef = Database.database().reference()
            getPublicToiletsData()
            getWaterFountainData()
            getAccessibleBuildings()
            getSteepnessData()
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        if accessibleBuildingList.count == 0 {
        UIApplication.shared.beginIgnoringInteractionEvents()
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func getPublicToiletsData(){
        let toiletsRef =  databaseRef?.child(functionList[0])
        toiletsRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            self.publicToiletList.removeAll()
            for item in value.allKeys{
                let toiletInfo = value.object(forKey: item) as! NSDictionary
                var publicToilet = PublicToilet()
                publicToilet.id = item as! String
                publicToilet.category = toiletInfo.object(forKey: "Category") as! String
                publicToilet.detail = toiletInfo.object(forKey: "Details") as! String
                publicToilet.desc = toiletInfo.object(forKey: "Description") as! String
                publicToilet.disableFlag = toiletInfo.object(forKey: "DisableFlag") as! String
                publicToilet.latitude = toiletInfo.object(forKey: "Latitude") as! Double
                publicToilet.longitude = toiletInfo.object(forKey: "Longitude") as! Double
                self.publicToiletList.append(publicToilet)
            }
            
        })
        
    }
    
    func getAccessibleBuildings(){
        let accessibleBuildingsRef = databaseRef?.child(functionList[2]).queryOrdered(byChild: "DisableFlag").queryEqual(toValue: "Yes")
        accessibleBuildingsRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            self.accessibleBuildingList.removeAll()
            for item in value.allKeys{
                let buildingInfo = value.object(forKey: item) as! NSDictionary
                var building = AccessibleBuildings()
                building.id = item as! String
                building.category = buildingInfo.object(forKey: "Category") as! String
                building.details = buildingInfo.object(forKey: "Details") as! String
                building.desc = buildingInfo.object(forKey: "Description") as! String
                building.disableFlag = buildingInfo.object(forKey: "DisableFlag") as! String
                building.latitude = buildingInfo.object(forKey: "Latitude") as! Double
                building.longitude = buildingInfo.object(forKey: "Longitude") as! Double
                self.accessibleBuildingList.append(building)
                
            }
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            
        })
    }
    
    func getWaterFountainData(){
        let waterRef =  databaseRef?.child(functionList[1])
        waterRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            self.waterFountainList.removeAll()
            for item in value.allKeys{
                let waterInfo = value.object(forKey: item) as! NSDictionary
                var waterFountain = WaterFountain()
                waterFountain.id = item as! String
                waterFountain.desc = waterInfo.object(forKey: "Description") as! String
                waterFountain.detail = waterInfo.object(forKey: "Details") as! String
                waterFountain.category = waterInfo.object(forKey: "Category") as! String
                waterFountain.disableFlag = waterInfo.object(forKey: "DisableFlag") as! String
                waterFountain.latitude = waterInfo.object(forKey: "Latitude") as! Double
                waterFountain.longitude = waterInfo.object(forKey: "Longitude") as! Double
                self.waterFountainList.append(waterFountain)
            }
            
        })
    }
    
    func getSteepnessData(){
        let steepnessRef = databaseRef?.child("SteepNess")
        steepnessRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            for item in value.allKeys{
                let steepInfo = value.object(forKey: item) as! NSDictionary
                let coordinates = (steepInfo.object(forKey: "coordinates")!)
                let array = NSArray()
                print(array)
            }
            
        })
        
        }
    func putWaterFountainOnMap() -> [CustomPointAnnotation]{
        var waterfountainAnnotationList : [CustomPointAnnotation] = []
        for fountain in self.waterFountainList{
            var annotation = CustomPointAnnotation()
            annotation.title = fountain.category!
            annotation.hiddenMessage = fountain.detail! 
            annotation.subtitle = fountain.desc!
            annotation.coordinate = CLLocationCoordinate2DMake(fountain.latitude!, fountain.longitude!)
            if fountain.disableFlag == "Yes"{
                annotation.imageName = "water-20"
            }else{
                annotation.imageName = "water-no-20"
            }
            waterfountainAnnotationList.append(annotation)
 
        }
        return waterfountainAnnotationList

    }
    
    func putToiletsOnMap() -> [CustomPointAnnotation]{
        var toiletAnnotationList: [CustomPointAnnotation] = []
        for toilet in self.publicToiletList{
            var annotation = CustomPointAnnotation()
            annotation.title = toilet.category!
            annotation.subtitle = toilet.desc!
            annotation.hiddenMessage = toilet.detail
            annotation.coordinate = CLLocationCoordinate2DMake(toilet.latitude!, toilet.longitude!)
            if toilet.disableFlag == "Yes"{
                annotation.imageName = "toliet-20"
            }else{
                annotation.imageName = "toliet-no-20"
            }
            toiletAnnotationList.append(annotation)
        }
        return toiletAnnotationList
        }

    
    func putAccessibleBuildingOnMap() -> [CustomPointAnnotation]{
        var accessibleBuildingsAnnotationList: [CustomPointAnnotation] = []
        for building in self.accessibleBuildingList{
            var annotation = CustomPointAnnotation()
            annotation.title = building.category!
            annotation.subtitle = building.desc! + building.details!
            annotation.coordinate = CLLocationCoordinate2DMake(building.latitude!, building.longitude!)
            annotation.hiddenMessage = building.details
            annotation.imageName = "building-20"
            accessibleBuildingsAnnotationList.append(annotation)
        }
        return accessibleBuildingsAnnotationList

    }
    
    func getAllFacilities(){
        self.annotationList.append(contentsOf: putWaterFountainOnMap())
        self.annotationList.append(contentsOf: putToiletsOnMap())
        self.annotationList.append(contentsOf: putAccessibleBuildingOnMap())
    }
    
    func alongWithTheRoute(){
        
        self.putToiletsOnMap()
        self.putWaterFountainOnMap()
        
    }

    @IBAction func publicToiletsClicked(_ sender: Any) {
        annotationList.removeAll()
        self.annotationList.append(contentsOf: putToiletsOnMap())
        self.nearby = false
        performSegue(withIdentifier: "showMap", sender: self)
    }
    

    @IBAction func waterFountainsClicked(_ sender: Any) {
        annotationList.removeAll()
        self.annotationList.append(contentsOf: putWaterFountainOnMap())
        
        self.nearby = false
        performSegue(withIdentifier: "showMap", sender: self)
        
    }
    
    @IBAction func accessibleBuildings(_ sender: Any) {
        annotationList.removeAll()
        self.annotationList.append(contentsOf: putAccessibleBuildingOnMap())
        self.nearby = false
        performSegue(withIdentifier: "showMap", sender: self)
        
    }
    
    @IBAction func nearbyClicked(_ sender: Any) {
        annotationList.removeAll()
        getAllFacilities()
        self.nearby = true
        performSegue(withIdentifier: "showMap", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if toiletsAndWaterFountainList.count == 0 {
            toiletsAndWaterFountainList.append(contentsOf: putWaterFountainOnMap())
            toiletsAndWaterFountainList.append(contentsOf: putToiletsOnMap())
        }
        if segue.identifier == "showMap"{
            let controller = segue.destination as! MapViewController
            controller.annotationList = self.annotationList
            controller.nearby = self.nearby
        }else if segue.identifier == "startSearch"{
            let controller = segue.destination as! searchPageController
            controller.annotationList = self.annotationList 
        }
    }
    
    @IBAction func searchClicked(_ sender: Any) {
        annotationList.removeAll()
        annotationList.append(contentsOf: putWaterFountainOnMap())
        annotationList.append(contentsOf: putToiletsOnMap())
        self.nearby = false
        self.performSegue(withIdentifier: "startSearch", sender: self)
    }
    
    
    
}
