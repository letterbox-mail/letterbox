//
//  LoggerTests.swift
//  enzevalos_iphoneTests
//
//  Created by Joscha on 16.11.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import XCTest

class LoggerTests: XCTestCase {

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

    func testLogWriting() {
        let testString = "This is a test String"
        let testFile = "testLog.json"
        Logger.saveToDisk(json: testString, fileName: testFile)

        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

            let fileURL = dir.appendingPathComponent(testFile)

            XCTAssert(FileManager.default.fileExists(atPath: fileURL.path))
        }
    }
}
