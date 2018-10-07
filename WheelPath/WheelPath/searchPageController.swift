//
//  searchPageController.swift
//  WheelPath
//
//  Created by Salamender Li on 7/9/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class searchPageController: UIViewController, UISearchBarDelegate, UITableViewDelegate,UITableViewDataSource {

  
    var optionList = ["start", "destination"]
    
    var startUserDefaultList : [String] = []
    var destinationUserDefaultList : [String] = []
    
    var searchProtocol: searchForDestination?
    var startItem : MKMapItem?
    
    var destinationItem : MKMapItem?
    
    @IBOutlet weak var startPointSearchBar: UISearchBar!
    
    @IBOutlet weak var destinationSearchBar: UISearchBar!
    
    @IBOutlet weak var destinationTableView: UITableView!
    
    @IBOutlet weak var startPointTableView: UITableView!
    
    //to check internet connection
    var reachability : Reachability?
    
    var startList : [MKMapItem] = []
    
    var destinationList : [MKMapItem] = []
    
    @IBOutlet weak var goButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
         self.reachability = Reachability.init()
        startPointSearchBar.delegate = self
        destinationSearchBar.delegate = self
        self.startPointTableView.isHidden = true
        self.startPointTableView.dataSource = self
        self.startPointTableView.delegate = self
        self.destinationTableView.dataSource = self
        self.destinationTableView.isHidden = true
        self.destinationTableView.delegate = self
        
        self.startUserDefaultList = self.getArrayFromUserDefault(option: optionList.first!)
        self.destinationUserDefaultList = self.getArrayFromUserDefault(option: optionList.last!)

        goButton.layer.cornerRadius = 0.5 * goButton.bounds.size.width
        goButton.clipsToBounds = true
        goButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        goButton.layer.shadowRadius = 5
        goButton.layer.shadowOpacity = 0.3
        
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if searchBar == self.startPointSearchBar{
            self.startPointTableView.isHidden = false
            self.view.bringSubview(toFront: startPointTableView)
        }else if searchBar == self.destinationSearchBar{
            self.destinationTableView.isHidden = false
            self.view.bringSubview(toFront: destinationTableView)
        }
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if searchBar == self.startPointSearchBar{
            startPointTableView.isHidden = true
        }else if searchBar == self.destinationSearchBar{
            destinationTableView.isHidden = true
        }
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar == self.startPointSearchBar{
        searchForLocation(location: searchText, option: self.optionList[0])
        }else{
            searchForLocation(location: searchText, option: self.optionList[1])
        }
    }

    
    func searchForLocation(location: String, option:String){
        
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

            if response == nil{
            }else{
                //Remove annotations
                if option == self.optionList[1]{
                    let tempList = (response?.mapItems)!
                     self.destinationList = tempList.filter{ (item : MKMapItem) -> Bool in
                        return item.placemark.countryCode == "AU"
                    }
                   
                    self.destinationTableView.reloadData()
                    
                }else{
                    self.startList = (response?.mapItems)!.filter{ (item : MKMapItem) -> Bool in
                        return item.placemark.countryCode == "AU"
                    }
                    self.startPointTableView.reloadData()
                }
                
            }
            
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.startPointTableView{
            return 3
        }else{
            return 4
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.startPointTableView{
            if section == 0 {
                return 1
            }else if section == 1{
                return self.startList.count
            }else{
                return self.startUserDefaultList.count
            }
        }else{
            if section == 0{
                return destinationList.count
            }else if section == 1 {
                return 1
            }else if section == 2{
                return 1
            }else{
                return self.destinationUserDefaultList.count
            }
        }
    }
    

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if tableView == self.startPointTableView{
            
            if indexPath.section == 0{
                cell = self.startPointTableView.dequeueReusableCell(withIdentifier: "currentLocationCell")!
                cell.textLabel?.text = "Current Location"
                cell.textLabel?.textColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
            }else if indexPath.section == 1{
                cell = self.startPointTableView.dequeueReusableCell(withIdentifier: "startPointCell")!
                cell.textLabel?.font = cell.textLabel?.font.withSize(14)
                cell.textLabel?.text = startList[indexPath.row].name!
                cell.detailTextLabel?.text = startList[indexPath.row].placemark.title
            }else if indexPath.section == 2{
                cell = self.startPointTableView.dequeueReusableCell(withIdentifier: "startPointHistoryCell")!
                cell.textLabel?.text = self.startUserDefaultList.reversed()[indexPath.row]
                cell.textLabel?.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }

            return cell 
        }else{
            if indexPath.section == 0{
                cell = self.destinationTableView.dequeueReusableCell(withIdentifier: "destinationCell")!
                cell.textLabel?.font = cell.textLabel?.font.withSize(14)
                cell.textLabel?.text = destinationList[indexPath.row].name
                cell.detailTextLabel?.text = destinationList[indexPath.row].placemark.title
            }else if indexPath.section == 1{
                cell = self.destinationTableView.dequeueReusableCell(withIdentifier: "toiletCell")!
                cell.textLabel?.text = "Nearest Public Toilet"
                cell.textLabel?.textColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
            }else if indexPath.section == 2{
                cell = self.destinationTableView.dequeueReusableCell(withIdentifier: "fountainCell")!
                cell.textLabel?.text = "Nearest Water Fountain"
                cell.textLabel?.textColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
            }else{
                cell = self.destinationTableView.dequeueReusableCell(withIdentifier: "destinationHistoryCell")!
                cell.textLabel?.text = self.destinationUserDefaultList.reversed()[indexPath.row]
                cell.textLabel?.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.startPointTableView{
            if indexPath.section == 1{
            self.startPointSearchBar.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
            self.startItem = self.startList[indexPath.row]
            self.startPointSearchBar.resignFirstResponder()
            tableView.isHidden = true
            }else if indexPath.section == 0{
                self.startPointSearchBar.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
                self.startPointSearchBar.resignFirstResponder()
                self.startItem = nil
                tableView.isHidden = true
            }else if indexPath.section == 2{
                self.startPointSearchBar.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
                searchForDestinationFromName(LocationName: (tableView.cellForRow(at: indexPath)?.textLabel?.text)! , option: optionList.first!)
                self.startPointSearchBar.resignFirstResponder()
                tableView.isHidden = true
            }
        }else{
            if indexPath.section == 0{
                self.destinationSearchBar.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
                self.destinationItem = self.destinationList[indexPath.row]
                self.destinationSearchBar.resignFirstResponder()
            }else if indexPath.section == 1 || indexPath.section == 2{
                self.destinationSearchBar.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
                self.destinationSearchBar.resignFirstResponder()
            }else if indexPath.section == 3{
                self.destinationSearchBar.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
                searchForDestinationFromName(LocationName: (tableView.cellForRow(at: indexPath)?.textLabel?.text)! , option: optionList.last!)
                self.destinationSearchBar.resignFirstResponder()
            }
            tableView.isHidden = true
        }
    }
    
    @IBAction func searchRoute(_ sender: Any) {
       print( CLLocationManager.locationServicesEnabled())
        if ((self.reachability!.connection) == .cellular || (self.reachability!.connection == .wifi)){
        // if the destinationIte is nil
            if self.destinationItem == nil{
                let text = self.destinationSearchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                // if the text is  "Nearest Public Toilet" or "Nearest Water Fountain"
                if text == "Nearest Public Toilet" || text == "Nearest Water Fountain"{
                    //if startItem is nil
                    if self.startItem == nil{
                        // if the text is "Current Location"
                        if self.startPointSearchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "Current Location"{
                            self.searchProtocol?.searchforDestination(destination: nil, startPoint: nil, nearestDestination: text)
                            self.navigationController?.popViewController(animated: true)
                        }else{
                            // no start Point
                            displayErrorMessage(title: "Error", message: "No start point Detected")
                        }
                    }else{
                        //with ok
                        
                        self.searchProtocol?.searchforDestination(destination: nil, startPoint: self.startItem, nearestDestination: text)
                        if !self.startUserDefaultList.contains((self.startItem?.name)!){
                            self.startUserDefaultList.append((self.startItem?.name)!)
                        }
                        self.addMapItemInToUserDefault(option: optionList.first!)
                        self.navigationController?.popViewController(animated: true)
                    }
                }else{
                    // error
                    displayErrorMessage(title: "Error", message: "No destination Detected")
                }
            
            }else{
               // the destination item is not nil
                if self.startItem == nil{
                    if self.startPointSearchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "Current Location"{
                        // if the text is "Current Location"
                        self.searchProtocol?.searchforDestination(destination: self.destinationItem!, startPoint: nil, nearestDestination: nil)
                        if !self.destinationUserDefaultList.contains((self.destinationItem?.name)!){
                            self.destinationUserDefaultList.append((self.destinationItem?.name)!)
                        }
                        self.destinationUserDefaultList.append((self.destinationItem?.name)!)
                        self.addMapItemInToUserDefault(option: optionList.last!)
                        self.navigationController?.popViewController(animated: true)
                    }else{
                        // no start Point not current location should fail
                        displayErrorMessage(title: "Error", message: "No start point Detected")
                    }
                }else{
                    // with start and destination
                    self.searchProtocol?.searchforDestination(destination: self.destinationItem!, startPoint: self.startItem, nearestDestination: nil)
                    if !self.destinationUserDefaultList.contains((self.destinationItem?.name)!){
                        self.destinationUserDefaultList.append((self.destinationItem?.name)!)
                    }
                    if !self.startUserDefaultList.contains((self.startItem?.name)!){
                        self.startUserDefaultList.append((self.startItem?.name)!)
                    }
                    self.addMapItemInToUserDefault(option: optionList.first!)
                    self.addMapItemInToUserDefault(option: optionList.last!)
                    self.navigationController?.popViewController(animated: true)
                }
            
            }
        }else{
            displayErrorMessage(title: "Error", message: "No Internet Connection")
        }
    }
    

    
    override func viewDidDisappear(_ animated: Bool) {
        self.startPointSearchBar.text = ""
        self.startItem = nil
        self.destinationSearchBar.text = ""
        self.destinationItem = nil
    }
    
    func displayErrorMessage(title:String, message: String){
        let alertview = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertview.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:nil))
        self.present(alertview, animated: true, completion: nil)
        
    }
    
    
    func addMapItemInToUserDefault(option: String){
        if option == self.optionList.first{
             UserDefaults.standard.set(startUserDefaultList, forKey: option)
        }else{
            UserDefaults.standard.set(destinationUserDefaultList, forKey: option)
        }
    }
    
    func getArrayFromUserDefault(option: String) -> [String]{
        if UserDefaults.standard.array(forKey:option) != nil{
            return UserDefaults.standard.array(forKey: option) as! [String]
        }else{
            return []
        }
    }
    
    func searchForDestinationFromName(LocationName:String,option :String) {
        if ((self.reachability!.connection) == .cellular || (self.reachability!.connection == .wifi)){
        UIApplication.shared.beginIgnoringInteractionEvents()
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = LocationName
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start{
            (response,error) in
            
            activityIndicator.stopAnimating()
            
            if response == nil{
            }else{
                //Remove annotations
                if option == self.optionList[0]{
                    let tempList = (response?.mapItems)!
                    self.startItem = tempList.first
                    
                }else{
                    self.destinationItem = response?.mapItems.first

                }
                UIApplication.shared.endIgnoringInteractionEvents()
            }
            
        }
        }else{
            displayErrorMessage(title: "Error", message: "No Internet Connection")
        }
    }
}
