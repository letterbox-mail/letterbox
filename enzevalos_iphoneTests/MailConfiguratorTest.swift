//
//  MailConfiguratorTest.swift
//  enzevalos_iphoneTests
//
//  Created by Oliver Wiese on 26.07.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import XCTest

@testable import enzevalos_iphone
class MailConfiguratorTest: XCTestCase {
    let username = "ullimuelle@web.de"
    let password = "dun3bate"
    let wrongPassword = "abc"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testImapFileExample() {
        let exp = expectation(description: "Check imap")
        let web = MailConfigurator.init(useraddr: username, password: password)
        web.checkSettings({ (works: Bool) -> () in
            XCTAssertTrue(works)
            exp.fulfill()
        })
        waitForExpectations(timeout: 5, handler: {error in
            if let error = error {
                XCTFail("Wait for expectations with error \(error)")
            }
        })
    }
    
    func testImapWrongPW() {
        let exp = expectation(description: "Check imap")
        let web = MailConfigurator.init(useraddr: username, password: wrongPassword)
        web.checkSettings({ (works: Bool) -> () in
            XCTAssertFalse(works)
            exp.fulfill()
        })
        waitForExpectations(timeout: 5, handler: {error in
            if let error = error {
                XCTFail("Wait for expectations with error \(error)")
            }
        })
    }
    
    func testIteration(){
        let exp = expectation(description: "Check imap")
        let web = MailConfigurator.init(userAddr: username, password: password, imapHostname: "test.web.de", imapPort: 232, imapAuthType: MCOAuthType.SASLGSSAPI, imapConType: MCOConnectionType.TLS, smtpHostname: "test.web.de", smtpPort: 323, smtpAuthType: MCOAuthType.SASLGSSAPI, smtpConType: MCOConnectionType.TLS)
        web.findUserConfiguration({(works: Bool) -> () in
            XCTAssertTrue(works)
            exp.fulfill()
        })
        waitForExpectations(timeout: 100, handler: {error in
            if let error = error {
                XCTFail("Wait for expectations with error \(error)")
            }
        })
    }
    
    func testIterationFailed(){
        let exp = expectation(description: "Check imap")
        let web = MailConfigurator.init(userAddr: "test@example.com", password: "1234", imapHostname: "test.web.de", imapPort: 232, imapAuthType: MCOAuthType.SASLGSSAPI, imapConType: MCOConnectionType.TLS, smtpHostname: "test.web.de", smtpPort: 323, smtpAuthType: MCOAuthType.SASLGSSAPI, smtpConType: MCOConnectionType.TLS)
        web.findUserConfiguration({(works: Bool) -> () in
            XCTAssertFalse(works)
            exp.fulfill()
        })
        waitForExpectations(timeout: 100, handler: {error in
            if let error = error {
                XCTFail("Wait for expectations with error \(error)")
            }
        })
    }
        
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
