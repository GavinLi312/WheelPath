//
//  DestinationCell.swift
//  WheelPath
//
//  Created by Salamender Li on 12/9/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit

class DestinationCell: UITableViewCell {
    
    @IBOutlet weak var destName: UILabel!
    
    @IBOutlet weak var destAddress: UILabel!
    
    @IBOutlet weak var destImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
