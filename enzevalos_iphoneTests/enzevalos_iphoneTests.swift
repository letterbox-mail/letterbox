//
//  enzevalos_iphoneTests.swift
//  enzevalos_iphoneTests
//
//  Created by jakobsbode on 23.09.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import XCTest
@testable import enzevalos_iphone

class enzevalos_iphoneTests: XCTestCase {
    
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
    
    
    func isSorted(_ array: [KeyRecord]) -> Bool {
        let startIndex = 0
        let endIndex = array.count - 1
        
        var previousIndex = startIndex
        var currentIndex = (startIndex + 1)
        
        while currentIndex < endIndex {
            
            if array[previousIndex] > array[currentIndex] {
                return false
            }
            
            previousIndex = currentIndex
            currentIndex = (currentIndex + 1)
        }
        
        return true
    }
    
}
