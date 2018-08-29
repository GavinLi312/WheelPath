//
//  FunctionListController.swift
//  WheelPath
//
//  Created by Salamender Li on 22/8/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit
import Firebase

var functions = NSCache<NSString, NSArray>()
var functionList = ["Public Toilets","Water Fountains", "Accessible Building"]


class FunctionListController: UITableViewController {
    
    
//    var mapViewController : MapViewController?
    var databaseRef : DatabaseReference?
    var publicToiletList : [PublicToilet] = []
    var waterFountainList : [WaterFountain] = []
    var accessibleBuildingList : [AccessibleBuildings] = []
    var reachability : Reachability?
    var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView()

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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return functionList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellResuseIdentifier = "functionCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellResuseIdentifier, for: indexPath) as! UITableViewCell
        cell.textLabel?.text = functionList[indexPath.row]
        return cell
    }

    //get the public toilets from firebase
    func getPublicToiletsData(){
//        if reachability?.connection != .none{
        let toiletsRef =  databaseRef?.child(functionList[0])
        toiletsRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            
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
            functions.setObject(self.publicToiletList as! NSArray , forKey: functionList[0] as NSString)
        })

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if functions.object(forKey: functionList[0] as! NSString) == nil || functions.object(forKey: functionList[1] as! NSString) == nil || functions.object(forKey: functionList[1] as! NSString) == nil {
            let reachable = Reachability.init()
            if reachable?.connection != .cellular && reachable?.connection != .wifi{
            let alertView = UIAlertController(title: "No Internet Connection ", message: "Internet is not working, please turn it on.", preferredStyle: .alert)

            alertView.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { action in
                print(" no is clicked")

            }))
            self.present(alertView, animated: false, completion: nil)
            }else{
                activityIndicator.center = self.view.center
                activityIndicator.hidesWhenStopped = true
                activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
                view.addSubview(activityIndicator)
                
                activityIndicator.startAnimating()
                UIApplication.shared.beginIgnoringInteractionEvents()
                getPublicToiletsData()
                getWaterFountainData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                    self.activityIndicator.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                    self.performSegue(withIdentifier: "showMap", sender: self)
                }
            }
        }else{
            performSegue(withIdentifier: "showMap", sender: self)
        }
    }
    
    //get the water Fountain Data from the firebase
    func getWaterFountainData(){
        let waterRef =  databaseRef?.child(functionList[1])
        waterRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
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
            functions.setObject(self.waterFountainList as NSArray , forKey: functionList[1] as! NSString)
        })
    }
    
    func getAccessibleBuildings(){
        let accessibleBuildingsRef = databaseRef?.child(functionList[2]).queryOrdered(byChild: "DisableFlag").queryEqual(toValue: "Yes")
        accessibleBuildingsRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
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
            functions.setObject(self.accessibleBuildingList as NSArray, forKey: functionList[2] as NSString)
            print(functions.object(forKey: functionList[2] as NSString)?.count)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMap" {
            if let indexPath = tableView.indexPathForSelectedRow{
                let option = functionList[indexPath.row]
                let controller = segue.destination.childViewControllers.first as! MapViewController
                controller.option = option
            }
        }
    }
}
