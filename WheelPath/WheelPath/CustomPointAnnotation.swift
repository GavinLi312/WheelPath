//
//  CustomPointAnnotation.swift
//  WheelPath
//
//  Created by Salamender Li on 23/8/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import UIKit
import MapKit

class CustomPointAnnotation: MKPointAnnotation{
    var imageName : String!

}

// - Tag: usableToiletAnnotationView
class UsableToiletAnnotationView: MKMarkerAnnotationView {
    static let ReuseID = "usableToiletAnnotation"
    
    
    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        let btn = UIButton(type: .infoDark) as UIButton
        clusteringIdentifier = "usabletoilet"
        canShowCallout = true
        rightCalloutAccessoryView = btn
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultLow
        markerTintColor = UIColor.blue
        glyphImage = #imageLiteral(resourceName: "toliet-blue-20")
    }
}

// - Tag: unusableToiletAnnotationView
class UnusableToiletAnnotationView: MKMarkerAnnotationView {
    static let ReuseID = "unusableToiletAnnotation"
    
    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
         let btn = UIButton(type: .infoDark) as UIButton
        clusteringIdentifier = "unusabletoilet"
        canShowCallout = true
        
        rightCalloutAccessoryView = btn
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultLow
        markerTintColor = UIColor.red
        glyphImage = #imageLiteral(resourceName: "toliet-no-red-20")
    }
}

// - Tag: unusableToiletAnnotationView
class WaterFountainAnnotationView: MKMarkerAnnotationView {
    static let ReuseID = "waterFountainAnnotation"
    
    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        let btn = UIButton(type: .infoDark) as UIButton
        clusteringIdentifier = "waterFountain"
        canShowCallout = true
        rightCalloutAccessoryView = btn
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultLow
        markerTintColor = UIColor.blue
        glyphImage = #imageLiteral(resourceName: "water-blue-20")
    }
}

// - Tag: unusableToiletAnnotationView
class AccessibleBuildingAnnotationView: MKMarkerAnnotationView {
    static let ReuseID = "AccessibleBuildingAnnotation"
    
    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        let btn = UIButton(type: .infoDark) as UIButton
        clusteringIdentifier = "AccessibleBuilding"
        canShowCallout = true
        rightCalloutAccessoryView = btn
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh
        markerTintColor = UIColor.blue
        glyphImage = #imageLiteral(resourceName: "access building-blue-20")
    }
}

// - Tag: unusableToiletAnnotationView
class ParkingSpotAnnotationView: MKMarkerAnnotationView {
    static let ReuseID = "ParkingSpotAnnotation"
    
    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "ParkingSpot"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultLow
        markerTintColor = UIColor.brown
        glyphImage = #imageLiteral(resourceName: "parking-blue-20")
    }
}

