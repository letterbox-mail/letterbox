//
//  GamificationDataUnitTest.swift
//  enzevalos_iphone
//
//  Created by Moritz on 27.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//
import XCTest
@testable import enzevalos_iphone

class GamificationDataUnitTest: XCTestCase {
    var badges : [Badges]!
    
    override func setUp() {
        super.setUp()
        badges = GamificationData.sharedInstance.badges

        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        badges = nil
    }


    func testBadgePictures(){
        // tests if all image Names are correct and can be loaded
        for e in badges {
            // Test Main Badges
            let bundle = Bundle(for: type(of: self))
            
            let imageOn = UIImage.init(named: e.onName, in: bundle, compatibleWith: nil)
            XCTAssert(imageOn != nil, "Image \(e.onName) failed")
            let imageOff = UIImage.init(named: e.offName, in: bundle, compatibleWith: nil)
            XCTAssert(imageOff != nil, "Image \(e.offName) failed")

            // Test Subbadges

            let subarray = GamificationData.sharedInstance.subBadgesforBadge(badge: e.type)
            if subarray.count > 0 {
                for subelement in subarray {
                    let imageOn = UIImage.init(named: subelement.onName, in: bundle, compatibleWith: nil)
                    XCTAssert(imageOn != nil, "Subimage \(subelement.onName) failed")
                    let imageOff = UIImage.init(named: subelement.offName, in: bundle, compatibleWith: nil)
                    XCTAssert(imageOff != nil, "Subimage \(subelement.offName) failed")
                }
            }

        }

    }

    func testWidth(){
        let arrow = ArrowView()
        let circle = CircleView()

         XCTAssert( arrow.width == circle.width , "LineStrokes not identical")

    }
    /*
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }*/
    
}
