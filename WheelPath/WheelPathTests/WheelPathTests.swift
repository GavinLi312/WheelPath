//
//  WheelPathTests.swift
//  WheelPathTests
//
//  Created by Salamender Li on 20/8/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import XCTest
import Firebase
import MapKit
@testable import WheelPath

class WheelPathTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    // test the PublicToiletList is not empty
    func testPublicToilets(){
        let expectation = XCTestExpectation(description: "can get access to the firebase Toilets table")
        let databaseRef =  Database.database().reference().child("Public Toilets")

        let url = URL(string: "\(databaseRef)")!
        
        let dataTask = URLSession.shared.dataTask(with: url){ (data, _, _) in
            
            XCTAssertNotNil(data, "No data was downloaded.")
            
            expectation.fulfill()
            
        }
        dataTask.resume()
        wait(for: [expectation], timeout: 10.0)
        }
    
    func testWaterFountains(){
        let expectation = XCTestExpectation(description: "can get access to the firebase Water Fountains table")
        let databaseRef =  Database.database().reference().child("Water Fountains")
        
        let url = URL(string: "\(databaseRef)")!
        
        let dataTask = URLSession.shared.dataTask(with: url){ (data, _, _) in
            
            XCTAssertNotNil(data, "No data was downloaded.")
            
            expectation.fulfill()
            
        }
        dataTask.resume()
        wait(for: [expectation], timeout: 10.0)
    }
    // the steepness API works
    func testSteepNessAPI() {
        let controller = MapViewController()
        let expectation = XCTestExpectation(description: "can get access to the firebase Water Fountains table")
        let location = CLLocationCoordinate2DMake(-37.815398, 144.957177)
        let query = controller.APIQuery(coordinate: location)
        let url = URL(string: controller.APIaddress + query + controller.APIToken)
        print(url)
        let dataTask = URLSession.shared.dataTask(with: url!){ (data, _, _) in
            print(data)
            XCTAssertNotNil(data, "No data was downloaded.")
            
            expectation.fulfill()
            
        }
        dataTask.resume()
        wait(for: [expectation], timeout: 10.0)
    }
    
}
