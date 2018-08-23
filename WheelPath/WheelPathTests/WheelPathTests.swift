//
//  WheelPathTests.swift
//  WheelPathTests
//
//  Created by Salamender Li on 20/8/18.
//  Copyright © 2018 Salamender Li. All rights reserved.
//

import XCTest
import Firebase
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
        let databaseRef =  Database.database().reference().child("Public Toilets")
        var publicToiletList : [(key: String, value: NSDictionary)] = []
        
        databaseRef.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let value = snapshot.value as? NSDictionary else{
                return
            }
            for item in value.allKeys{
                publicToiletList.append((item as! String, value[item] as! NSDictionary))
            }
            XCTAssertNotNil(publicToiletList)
            XCTAssertFalse(publicToiletList.count == 0)
        })
        
    }
    
}
