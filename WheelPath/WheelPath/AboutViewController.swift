//
//  AboutViewController.swift
//  WheelPath
//
//  Created by Salamender Li on 29/8/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var Description: UILabel!
    
    
    @IBOutlet weak var Content: UILabel!
    
    @IBOutlet weak var appImage: UIImageView!
    
    
    override func viewDidLoad() {


        Content.numberOfLines = 0
        appImage.layer.cornerRadius = 0.5
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
