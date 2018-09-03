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

class menueController: UIViewController {
    
    
    var nearby = false
    
    var databaseRef : DatabaseReference?
    
    var publicToiletList : [PublicToilet] = []
    
    var waterFountainList : [WaterFountain] = []
    
    var accessibleBuildingList : [AccessibleBuildings] = []
    
    var reachability : Reachability?
    
    var annotationList : [CustomPointAnnotation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reachability = Reachability.init()
        if ((self.reachability!.connection) == .cellular || (self.reachability!.connection == .wifi)){
            print(reachability!.connection)
            databaseRef = Database.database().reference()
            getPublicToiletsData()
            getWaterFountainData()
            getAccessibleBuildings()
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
                building.desc = buildingInfo.object(forKey: "Description") as! String
                building.disableFlag = buildingInfo.object(forKey: "DisableFlag") as! String
                building.latitude = buildingInfo.object(forKey: "Latitude") as! Double
                building.longitude = buildingInfo.object(forKey: "Longitude") as! Double
                self.accessibleBuildingList.append(building)
                
            }
            
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
                waterFountain.disableFlag = waterInfo.object(forKey: "DisableFlag") as! String
                waterFountain.latitude = waterInfo.object(forKey: "Latitude") as! Double
                waterFountain.longitude = waterInfo.object(forKey: "Longitude") as! Double
                self.waterFountainList.append(waterFountain)
            }
            
        })
    }
    
    func putWaterFountainOnMap(){

        for fountain in self.waterFountainList{
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
    
    func putToiletsOnMap() {
        for toilet in self.publicToiletList{
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

    func putAccessibleBuildingOnMap(){

        for building in self.accessibleBuildingList{
            var annotation = CustomPointAnnotation()
            annotation.title = building.id!
            annotation.subtitle = building.desc!
            annotation.coordinate = CLLocationCoordinate2DMake(building.latitude!, building.longitude!)
            annotation.imageName = "access-20"
            self.annotationList.append(annotation)
        }

    }
    
    func getAllFacilities(){
        putWaterFountainOnMap()
        putToiletsOnMap()
        putAccessibleBuildingOnMap()
    }

    @IBAction func publicToiletsClicked(_ sender: Any) {
        annotationList.removeAll()
        putToiletsOnMap()
        self.nearby = false
        performSegue(withIdentifier: "showMap", sender: self)
    }
    

    @IBAction func waterFountainsClicked(_ sender: Any) {
        annotationList.removeAll()
        putWaterFountainOnMap()
        self.nearby = false
        performSegue(withIdentifier: "showMap", sender: self)
        
    }
    
    @IBAction func accessibleBuildings(_ sender: Any) {
        annotationList.removeAll()
        putAccessibleBuildingOnMap()
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
        if segue.identifier == "showMap"{
            let controller = segue.destination as! MapViewController
            controller.annotationList = self.annotationList
            controller.nearby = self.nearby
        }
    }
    
}
