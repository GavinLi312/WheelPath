//
//  custommkPolygon.swift
//  WheelPath
//
//  Created by Salamender Li on 12/9/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit
import MapKit

class custommkPolygon: MKPolygon{
    var colorLevel = 0
}

struct Steepness {
    var key : String = ""
    var steepnessFlag = 0
    var coordinates : [[[[Double]]]] = [[[[0]]]]
}
