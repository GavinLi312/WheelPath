//
//  SimpleViewController.swift
//  WheelPath
//
//  Created by Salamender Li on 1/10/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit
import MapKit

class SimpleViewController: UIViewController, CLLocationManagerDelegate{

    @IBOutlet weak var startButton: UIButton!
    let manager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        if CLLocationManager.locationServicesEnabled(){
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                manager.requestAlwaysAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
            }
        }
        if startButton != nil{
        setButtonLayout()
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setButtonLayout() {
        startButton.backgroundColor = UIColor.white
        startButton.setTitle("      Get Start!      ",for:.normal)
        startButton.setTitleColor(UIColor(red: 59/255, green: 178/255, blue: 208/255, alpha: 1),for:.normal)
        startButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 18)
        startButton.layer.cornerRadius = 25
        startButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        startButton.layer.shadowRadius = 5
        startButton.layer.shadowOpacity = 0.3
    }



}
