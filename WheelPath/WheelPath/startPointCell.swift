//
//  startPointCell.swift
//  WheelPath
//
//  Created by Salamender Li on 12/9/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit

class startPointCell: UITableViewCell {

    @IBOutlet weak var startLocation: UILabel!
    
    @IBOutlet weak var startLocationAddress: UILabel!
    
    @IBOutlet weak var startImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
