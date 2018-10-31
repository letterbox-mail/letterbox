//
//  MailTest.swift
//  
//
//  Created by Oliver Wiese on 31.10.18.
//

import XCTest

/*
 Test cases:
 
 parse incoming mails:
 MUA = {Letterbox, AppleMail, iOSMail, Thunderbird (+ Enigmail), K9 (+ OKC)(, WebMail)}
 MUA x EncState x SigState (x Attachment)
 
 parse pgp mails:
    * inline pgp
    * mime pgp
 
 parse special mails:
    * public key import (Autocrypt, attachment, inline)
    * secret key import (Autocryp,t attachment, inline)
 
 parse autocrypt:
    * header fields
 
 parse mail compontens:
    * header (to, cc, bcc, subject, date etc.)
    * body
    * attachments
 
What about errors and special cases?
    * mixed encState/sigState in mail
    * html mail
    * attachments
    * remote content
    * java script
 
 create Mails: -> Export as eml (in Message builder)?
    * EncState x SigState -> is correct?
    * mixed receivers (plain, enc) -> Text if matching is correct
    * add autocrypt header
    * attach public key
    * export secret key
 
 TODOS:
 What about input validation e.g. addr: b@example
 */

@testable import enzevalos_iphone
class MailTest: XCTestCase {
    let datahandler = DataHandler.handler
    let mailHandler = AppDelegate.getAppDelegate().mailHandler
    let pgp = SwiftPGP()
    let userAdr = "alice@example.com"
    let userName = "alice"
    var user: MCOAddress = MCOAddress.init(mailbox: "alice@example.com")
    var userKeyID: String = ""
    
    override func setUp() {
        super.setUp()
        datahandler.reset()
        pgp.resetKeychains()
        XCTAssertEqual(datahandler.findSecretKeys().count, 0)
        XCTAssertEqual(datahandler.allFolders.count, 0)
        XCTAssertEqual(datahandler.getContacts().count, 0)
        XCTAssertEqual(datahandler.getAddresses().count, 0)
        (user, userKeyID) = owner()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    
    func testSimpleMailCreation() {
        // Init
        let tos = ["to1@example.com", "to2@example.com"]
        let ccs = ["cc1@example.com"]
        let bccs = ["bcc1@example.com"]
        let subject = "subject"
        let body = "This is the body"
        let outMail = OutgoingMail(toEntrys: tos, ccEntrys: ccs, bccEntrys: bccs, subject: subject, textContent: body, htmlContent: nil)
        if let parser = MCOMessageParser(data: outMail.plainData) {
            // Test parsing!
            if let mail = mailHandler.parseMail(parser: parser, record: nil, folderPath: "INBOX", uid: 0, flags: MCOMessageFlag.seen){
                XCTAssertTrue(MailTest.compareAdrs(adrs1: tos, adrs2: mail.getReceivers()))
                XCTAssertTrue(MailTest.compareAdrs(adrs1: ccs, adrs2: mail.getCCs()))
                XCTAssertTrue(mail.getBCCs().count == 0)
                XCTAssertEqual(subject, mail.subject)
                XCTAssertEqual(body, mail.body)
                XCTAssertFalse(mail.isSecure)
            }
            else {
                XCTFail()
            }
        }
        else {
            XCTFail()
        }
    }
    
    func testSecureMailCreation() {
        let encAdr = "enc@example.com"
        let subject = "subject"
        let body = "body"
        _ = createPGPUser(adr: encAdr, name: encAdr)
        let outMail = OutgoingMail(toEntrys: [encAdr], ccEntrys: [], bccEntrys: [], subject: subject, textContent: body, htmlContent: nil)
        if let parser = MCOMessageParser(data: outMail.pgpData){
            if let mail = mailHandler.parseMail(parser: parser, record: nil, folderPath: "INBOX", uid: 1, flags: MCOMessageFlag.seen) {
                XCTAssertEqual(body, mail.body)
                XCTAssertTrue(mail.isSecure)
            }
            else {
                XCTFail()
            }
        }
        else {
            XCTFail()
        }
    }
    
    func testMixedMailCreation() {
        let encAdr = "enc@example.com"
        let plainAdr = "plain@example.com"
        let subject = "subject"
        let body = "body"
        _ = createPGPUser(adr: encAdr, name: encAdr)
        let outMail = OutgoingMail(toEntrys: [plainAdr, encAdr], ccEntrys: [], bccEntrys: [], subject: subject, textContent: body, htmlContent: nil)
        if let secureParser = MCOMessageParser(data: outMail.pgpData) {
            if let mail = mailHandler.parseMail(parser: secureParser, record: nil, folderPath: "INBOX", uid: 2, flags: MCOMessageFlag.seen) {
                XCTAssertEqual(body, mail.body)
                XCTAssertTrue(mail.isSecure)
                XCTAssertTrue(MailTest.compareAdrs(adrs1: [encAdr, plainAdr], adrs2: mail.getReceivers()))
            }
            else {
                XCTFail()
            }
        }
        else {
            XCTFail()
        }
        if let insecureParser = MCOMessageParser(data: outMail.plainData) {
            if let mail = mailHandler.parseMail(parser: insecureParser, record: nil, folderPath: "INXBO", uid: 3, flags: MCOMessageFlag.seen) {
                XCTAssertEqual(body, mail.body)
                XCTAssertFalse(mail.isSecure)
                XCTAssertTrue(MailTest.compareAdrs(adrs1: [plainAdr, encAdr], adrs2: mail.getReceivers()))
            }
        }
        
    }
    
    static func compareAdrs(adrs1: [String], adrs2: [Mail_Address]) -> Bool{
        for adr in adrs1 {
            var found = false
            for adr2 in adrs2 {
                if adr == adr2.address {
                    found = true
                }
            }
            if !found {
                return false
            }
        }
        
        for adr in adrs2 {
            var found = false
            for adr2 in adrs1 {
                if adr.address == adr2 {
                    found = true
                }
            }
            if !found {
                return false
            }
        }
        return true
        
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        // Import eml file
        // Add content as data
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func createUser(adr: String = String.random().lowercased(), name: String = String.random()) -> MCOAddress {
        return MCOAddress.init(displayName: name, mailbox: adr.lowercased())
    }
    
    func createPGPUser(adr: String = String.random().lowercased(), name: String = String.random()) -> (MCOAddress, String) {
        let user = createUser(adr: adr, name: name)
        let id = pgp.generateKey(adr: user.mailbox)
        return (user, id)
    }
    
    func owner() -> (MCOAddress, String) {
        Logger.logging = false
        let (user, userid) = createPGPUser(adr: userAdr, name: userName)
        UserManager.storeUserValue(userAdr as AnyObject, attribute: Attribute.userAddr)
        UserManager.storeUserValue(userid as AnyObject, attribute: Attribute.prefSecretKeyID)
        return (user, userid)
    }
    
}
