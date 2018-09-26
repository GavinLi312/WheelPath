//
//  PublicToilet.swift
//  WheelPath
//
//  Created by Salamender Li on 23/8/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit
import MapKit

enum AccessibleFacilityType : Int{
    case accessiblePublicToilet
    case inaccessiblePublicToilet
    case waterFountain
    case accessibleBuilding
    case parkingSpot
}


class AccessibleFacilities: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D{
        return CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
    }
    var title: String?{
        return self.category
    }
    var subtitle: String?{
        return self.desc
    }
    var type:AccessibleFacilityType?
    var id : String?
    var desc: String?
    var detail: String?
    var category: String?
    var disableFlag: String?
    var latitude: Double?
    var longitude: Double?
    
}
