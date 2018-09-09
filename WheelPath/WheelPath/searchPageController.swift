//
//  searchPageController.swift
//  WheelPath
//
//  Created by Salamender Li on 7/9/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit
import MapKit
class searchPageController: UIViewController, UISearchBarDelegate, UITableViewDelegate,UITableViewDataSource {

    var optionList = ["start", "destination"]
    
    var annotationList : [CustomPointAnnotation] = []
    
    var startItem : MKMapItem?
    
    var destinationItem : MKMapItem?
    
    @IBOutlet weak var startPointSearchBar: UISearchBar!
    
    @IBOutlet weak var destinationSearchBar: UISearchBar!
    
    @IBOutlet weak var destinationTableView: UITableView!
    
    @IBOutlet weak var startPointTableView: UITableView!
    
    var startList : [MKMapItem] = []
    
    var destinationList : [MKMapItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startPointSearchBar.delegate = self
        destinationSearchBar.delegate = self
        self.startPointTableView.isHidden = true
        self.startPointTableView.dataSource = self
        self.startPointTableView.delegate = self
        self.destinationTableView.dataSource = self
        self.destinationTableView.isHidden = true
        self.destinationTableView.delegate = self
        // Do any additional setup after loading the view.
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
        //ignoring User

        
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

            if response == nil{
                print("ERROR")
            }else{
                //Remove annotations
                if option == self.optionList[1]{
                    var tempList = (response?.mapItems)!
                    tempList.filter{ (item : MKMapItem) -> Bool in
                        return item.placemark.countryCode == "AU"

                    }
                    self.destinationList = tempList
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
            return 2
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.startPointTableView{
            if section == 0 {
                return 1
            }else{
                return self.startList.count
            }
        }else{
            return destinationList.count
        }
    }
    

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if tableView == self.startPointTableView{
            
            if indexPath.section == 0{
                cell = self.startPointTableView.dequeueReusableCell(withIdentifier: "currentLocationCell")!
                cell.textLabel?.text = "current Location"
            }else{
                cell = self.startPointTableView.dequeueReusableCell(withIdentifier: "startPointCell")!
                cell.textLabel?.font = cell.textLabel?.font.withSize(14)
                cell.textLabel?.text = startList[indexPath.row].name!
                cell.detailTextLabel?.text = startList[indexPath.row].placemark.title
            }

            return cell 
        }else{
            cell = self.destinationTableView.dequeueReusableCell(withIdentifier: "destinationCell")!
            cell.textLabel?.font = cell.textLabel?.font.withSize(14)
            cell.textLabel?.text = destinationList[indexPath.row].name
            cell.detailTextLabel?.text = destinationList[indexPath.row].placemark.title
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("i am touched")
        if tableView == self.startPointTableView{
            if indexPath.section == 1{
            self.startPointSearchBar.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
            self.startItem = self.startList[indexPath.row]
            self.startPointSearchBar.resignFirstResponder()
            tableView.isHidden = true
            }else{
                self.startPointSearchBar.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
                self.startPointSearchBar.resignFirstResponder()
                self.startItem = nil
                tableView.isHidden = true
            }
        }else{
            self.destinationSearchBar.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
            self.destinationItem = self.destinationList[indexPath.row]
            self.destinationSearchBar.resignFirstResponder()
            
            tableView.isHidden = true
        }
    }
    
    @IBAction func searchRoute(_ sender: Any) {
        if self.destinationItem == nil{
            displayErrorMessage(title: "Error", message: "No Destination Detected")
            
        } else if self.startPointSearchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) == ""{
            displayErrorMessage(title: "Error", message: "No start point Detected")

        }else{
            self.performSegue(withIdentifier: "searchRoute", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchRoute"{
            let controller = segue.destination as! MapViewController
            controller.annotationList = self.annotationList
            controller.destinationItem = self.destinationItem
            if startItem == nil{
                controller.nearby = true
            }else{
                controller.nearby = false
                controller.startItem = self.startItem
            }
        }
    }
    
    func displayErrorMessage(title:String, message: String){
        let alertview = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertview.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:nil))
        self.present(alertview, animated: true, completion: nil)
    }
    
}
