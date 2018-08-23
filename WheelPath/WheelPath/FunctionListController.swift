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

class FunctionListController: UITableViewController {
    
    
    var mapViewController : MapViewController?
    var databaseRef : DatabaseReference?
    var publicToiletList : [(key: String, value: NSDictionary)] = []
    var waterFountainList : [(key: String, value: NSDictionary)] = []
    var functionList = ["Public Toilets","Water Fountains"]

    override func viewDidLoad() {
        super.viewDidLoad()
        databaseRef = Database.database().reference()
        getPublicToiletsData()
        getWaterFountainData()
    }

    override func viewWillAppear(_ animated: Bool) {

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
        let toiletsRef =  databaseRef?.child("Public Toilets")
        toiletsRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            for item in value.allKeys{
                self.publicToiletList.append((item as! String, value[item] as! NSDictionary))
            }
            functions.setObject(self.publicToiletList as NSArray, forKey: "public toilets")
            
        })
    }
    
    //get the water Fountain Data from the firebase
    func getWaterFountainData(){
        let toiletsRef =  databaseRef?.child("Water Fountains")
        toiletsRef?.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            for item in value.allKeys{
                self.waterFountainList.append((item as! String, value[item] as! NSDictionary))
            }
            functions.setObject(self.waterFountainList as NSArray, forKey: "water fountains")
        })
    }

}
