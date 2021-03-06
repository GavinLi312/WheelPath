//
//  InformationViewController.swift
//  WheelPath
//
//  Created by Salamender Li on 5/9/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit
import MapKit

class InformationViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var userLocation: CLLocation?
    
    var destination: CLLocation?
    
    var hiddenMessage: String?
    
    var destAdress : String = ""
    
    var destName : String = ""
    
    var startAddress : String = ""
    
    var startName : String = ""
    
    @IBOutlet weak var destinationName: UILabel!
    
    
    @IBOutlet weak var directionList: UITableView!
    
    @IBOutlet weak var transportControl: UISegmentedControl!
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    let optionList = ["StartPoint", "Destination"]
    
    var directionSteps : [MKRouteStep] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        directionList.delegate = self
        directionList.dataSource = self
        destinationName.layer.borderColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        destinationName.layer.cornerRadius = 5
        directionList.allowsSelection = false
        changeCoordinatoToAddress(animalLocation: userLocation!, option: optionList[0])
        changeCoordinatoToAddress(animalLocation: destination!, option: optionList[1])
        findNavigateSteps(startPoint: self.userLocation, destination: self.destination)
        directionList.layer.borderColor = #colorLiteral(red: 0.5783415437, green: 0.5783415437, blue: 0.5783415437, alpha: 0.3349208048)
        directionList.layer.borderWidth = 2.0
        directionList.backgroundColor = #colorLiteral(red: 0.5783415437, green: 0.5783415437, blue: 0.5783415437, alpha: 0.1917273116)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else if section == 1{
            
            return directionSteps.count
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if indexPath.section == 0 {
            var startcell = directionList.dequeueReusableCell(withIdentifier: "startPointCell") as! startPointCell
            startcell.startLocation.text = "Start Point"
            startcell.startLocationAddress.text = self.startAddress
            cell = startcell
            cell.backgroundColor = UIColor.clear
        }else if indexPath.section == 1{
            let directioncell = directionList.dequeueReusableCell(withIdentifier: "directionCell")
            var distance = Int(directionSteps[indexPath.row].distance)
            if distance > 1000 {
                directioncell?.textLabel?.text = "\(distance/1000) km"
                
            }else{
                directioncell?.textLabel?.text = "\(distance) m"
            }
            
            directioncell?.detailTextLabel?.text = "\(directionSteps[indexPath.row].instructions)"
            
            cell = directioncell!
            
        }else{
            var destCell = directionList.dequeueReusableCell(withIdentifier: "DestinationCell") as! DestinationCell
            destCell.destName.text = "Destination"
            destCell.destAddress.text = self.destAdress
            cell = destCell
            cell.backgroundColor = UIColor.clear
        }

        return cell
    }
    
    
    func changeCoordinatoToAddress(animalLocation: CLLocation, option: String)  {
        let gecoder = CLGeocoder()
        var name = ""
        var address = ""
        gecoder.reverseGeocodeLocation(animalLocation, completionHandler: {(placemarks,error) in
            if error == nil{
                let placemark = placemarks![0]
                name = placemark.name!
                address.append(placemark.name! + ", ")
                if placemark.locality != nil{
                address.append(placemark.locality! + ", ")
                }
                if placemark.postalCode != nil{
                address.append(placemark.postalCode! + ", ")
                }
                if placemark.subLocality != nil{
                address.append(placemark.subLocality! + ", ")
                }
                address.append(placemark.country!)
                if option == self.optionList[0] {
                    self.startName = name
                    self.startAddress = address
                }else{
                    self.destinationName.text = name
                    self.destName = name
                    if self.hiddenMessage != nil{
                         self.destinationName.text?.append("\n" + self.hiddenMessage!)
                        self.destName.append("\n" + self.hiddenMessage!)
                    }
                    self.destAdress = address
                    
                }
                self.directionList.reloadData()
                
            }else{
                self.displayErrorMessage(title: "Error", message: "No internet Connection, please check the internet.")
            }
            
        })
    }
    
    func displayErrorMessage(title:String , message: String){
        let alertview = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertview.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { action in
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alertview, animated: true, completion: nil)
        
    }
    
    func findNavigateSteps(startPoint:CLLocation?, destination:CLLocation?) {
        if startPoint == nil || destination == nil {
            displayErrorMessage(title: "Error", message: "Can't detect your currection location or destination")
        }else{
            let destinationPlacemark = MKPlacemark(coordinate: (self.destination?.coordinate)!)
            let sourcePlacemark = MKPlacemark(coordinate: (self.userLocation?.coordinate)!)
            let sourceItem = MKMapItem(placemark: sourcePlacemark)
            let destItem = MKMapItem(placemark: destinationPlacemark)
            let directionRequest = MKDirectionsRequest()
            directionRequest.source = sourceItem
            directionRequest.destination = destItem
            if transportControl.selectedSegmentIndex == 0{
                directionRequest.transportType = .walking
            }else{
                directionRequest.transportType = .automobile
            }
            directionRequest.requestsAlternateRoutes = false
            let directions = MKDirections(request: directionRequest)
            directions.calculate(completionHandler: {(response, error) in
                guard let response = response else{
                    if let error = error{
                        print(error)
                        //https://stackoverflow.com/questions/28152526/how-do-i-open-phone-settings-when-a-button-is-clicked
                        let alertView = UIAlertController(title: "No Permission ", message: "No Permission about the Location Service or Internet Connection, Want to change your setting?", preferredStyle: .alert)
                        var settingAction = UIAlertAction(title: "Yes", style: .default, handler: { action in
                            let settingUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                            if let url = settingUrl{
                                UIApplication.shared.openURL(url as URL)
                                self.navigationController?.popViewController(animated: true)
                            }
                        })
                        alertView.addAction(settingAction)
                        
                        alertView.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in
                            self.navigationController?.popViewController(animated: true)
                            
                        }))
                        self.present(alertView, animated: false, completion: nil)
                    }
                    return
                }
                
                let route = response.routes[0]
                let distance = Int(route.distance)
                if distance > 1000{
                    self.distanceLabel.text = "\(distance/1000) km away"
                }else{
                    self.distanceLabel.text = "\(distance) m away"
                }
                
                self.directionSteps = route.steps
                self.directionList.reloadData()
            })

        }
    }
    
    @IBAction func transportFunctionChanged(_ sender: Any) {
        self.findNavigateSteps(startPoint: self.userLocation, destination: self.destination)
    }
}
