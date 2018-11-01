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
 MUA = {Letterbox, AppleMail, iOSMail, Thunderbird (+ Enigmail) [DONE], K9 (+ OKC)(, WebMail)}
 MUA x EncState x SigState (x Attachment)
 
 parse pgp mails:
    * inline pgp DONE
    * mime pgp DONE
 
 parse special mails:
    * public key import (attachment, inline)
    * secret key import (attachment, inline)

 
 parse mail compontens:
    * header (to, cc, bcc, subject, date etc.) DONE
    * body DONE
    * attachments
 
What about errors and special cases?
    * mixed encState/sigState in mail
    * html mail
    * attachments
    * remote content
    * java script
 
 create Mails: -> Export as eml (in Message builder)?
    * EncState x SigState -> is correct?
    * mixed receivers (plain, enc) -> Text if matching is correct DONE
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
    let userAdr = "bob@enzevalos.de"
    let userName = "bob"
    var user: MCOAddress = MCOAddress.init(mailbox: "bob@enzevalos.de")
    var userKeyID: String = ""
    
    
    static let body = """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque dapibus id diam ac volutpat. Sed quis cursus ante. Vestibulum eget gravida felis. Nullam accumsan diam quis sem ornare lacinia. Aenean risus risus, maximus quis faucibus et, maximus at nunc. Duis pharetra augue libero, et congue diam varius eget. Nullam efficitur ex purus, non accumsan tellus laoreet hendrerit. Suspendisse gravida interdum eros, eu venenatis ante suscipit nec. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Praesent pellentesque cursus sem, non ornare nunc commodo vel. Praesent sed magna at ligula ultricies sagittis malesuada non est. Nam maximus varius mauris. Etiam dignissim congue ligula eu porta. Nunc rutrum nisl id mauris efficitur ultrices. Maecenas sit amet velit ac mauris consequat sagittis at et lorem.
    """
    override func setUp() {
        super.setUp()
        datahandler.reset()
        pgp.resetKeychains()
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
            else {
                XCTFail()
            }
        }
        else {
            XCTFail()
        }
    }
    
    func testSecretKeyImport(){
        
    }
    
    func testThunderbirdPlainMail() {
        testMailAliceToBob(name: "plainThunderbird", isSecure: false, encState: EncryptionState.NoEncryption, sigState: SignatureState.NoSignature)
    }
    func testThunderbirdSecureMail(){
        testSecureMail(name: "enc+signedThunderbird")
    }
    func testThunderBirdSecureInlineMail() {
        testSecureMail(name: "enc+signedInlineThunderbird")
    }
    func testThunderbirdEncMail(){
        testMailAliceToBob(name: "encThunderbird", isSecure: false, encState: EncryptionState.ValidedEncryptedWithCurrentKey, sigState: SignatureState.NoSignature)
    }
    func testThunderbirdEncInlineMail(){
        testMailAliceToBob(name: "encInlineThunderbird", isSecure: false, encState: EncryptionState.ValidedEncryptedWithCurrentKey, sigState: SignatureState.NoSignature)
    }
    func testThunderbirdSigedInlineMail() {
        //testMailAliceToBob(name: "signedInlineThunderbird", isSecure: false, encState: EncryptionState.NoEncryption, sigState: SignatureState.ValidSignature)
    }
    func testThunderbirdSigedMail() {
        //testMailAliceToBob(name: "signedThunderbird", isSecure: false, encState: EncryptionState.NoEncryption, sigState: SignatureState.ValidSignature)
    }
    
    func testSecureMail(name: String) {
        testMailAliceToBob(name: name, isSecure: true)
    }
    
    func testMailAliceToBob(name: String, isSecure: Bool, encState: EncryptionState? = nil, sigState: SignatureState? = nil) {
        testMailAliceToBob(pkExists: true, name: name, isSecure: isSecure, encState: encState, sigState: sigState)
        tearDown()
        setUp()
        testMailAliceToBob(pkExists: false, name: name, isSecure: isSecure, encState: encState, sigState: sigState)
    }
    
    func testMailAliceToBob(pkExists: Bool, name: String, isSecure: Bool, encState: EncryptionState? = nil, sigState: SignatureState? = nil) {
        let mailData = MailTest.loadMail(name: name )
        let (alice, _) = addAliceAndBob(addAlice: pkExists)
        if let parser = MCOMessageParser(data: mailData) {
            if let mail = mailHandler.parseMail(parser: parser, record: nil, folderPath: "INBOX", uid: 0, flags: MCOMessageFlag.seen) {
                XCTAssertEqual(mail.isSecure, isSecure)
                if mail.isSecure || mail.sigState == .ValidSignature{
                    XCTAssertEqual(mail.signedKey?.keyID, alice)
                    XCTAssertEqual(mail.keyID, alice)
                }
                if let encState = encState {
                    XCTAssertEqual(mail.encState, encState)
                }
                if let sigState = sigState {
                    XCTAssertEqual(mail.sigState, sigState)
                }
                if let body = mail.body {
                    XCTAssertEqual(body.removeNewLines(), MailTest.body.removeNewLines())
                }
                else {
                    XCTFail()
                }
                XCTAssertTrue(MailTest.compareAdrs(adrs1: ["bob@enzevalos.de"], adrs2: mail.getReceivers()))
            }
        }
    }
    
    func addAliceAndBob(addAlice: Bool) -> (alice: String, bob: String){
        let aliceKeyId = importKey(file: "alicePublic", isSecretKey: false)
        if addAlice {
            _ = datahandler.newPublicKey(keyID: aliceKeyId, cryptoType: .PGP, adr: "alice@enzevalos.de", autocrypt: true)
        }
        let bobKeyId = importKey(file: "bobSecret", isSecretKey: true)
        _ = datahandler.newSecretKey(keyID: bobKeyId, addPk: true)
        return (aliceKeyId, bobKeyId)
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
    
    func importKey(file: String, isSecretKey: Bool) -> String{
        let bundle = Bundle(for: type(of: self))
        do {
            let keyData = try Data(contentsOf: bundle.url(forResource: file, withExtension: "asc")!)
            let ids = try pgp.importKeys(data: keyData, pw: nil, secret: isSecretKey)
            if ids.count > 0 {
                return ids.first!
            }
        } catch {
            XCTFail()
        }
        XCTFail()
        return ""
    }
    
    static func loadMail(name: String) -> Data {
        let bundle = Bundle(for: self)
        do {
            let mail = try Data(contentsOf: bundle.url(forResource: name, withExtension: "eml")!)
            return mail
        } catch {
            XCTFail()
        }
        return Data(base64Encoded: "")!
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
