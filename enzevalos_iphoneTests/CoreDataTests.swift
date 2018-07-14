//
//  CoreDataTests.swift
//  enzevalos_iphoneTests
//
//  Created by Oliver Wiese on 30.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//
import XCTest

/*
 Testcases:
 One plain mail, one encrypted mail
 multiple plain mails form one adr, multiple encryted mails from one adr, multiple enc + plain mails from one adr
 plain mails from different adr, enc mails from different adr, enc+plain mails from different adr
 One EnzContact with multi adr/keys
 One adr with different keys
 
 Own ID
 
 Overview Enzcontacts, adr
 Test Inbox
 - #records
 - #Sortierung, #Mails
 Test EnzContact
 - #records
 
 */

@testable import enzevalos_iphone
class CoraDataTests: XCTestCase {
    let datahandler = DataHandler.handler
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
    }
    
    override func tearDown() {
        datahandler.reset()
        pgp.resetKeychains()
        super.tearDown()
    }
    
    func createUser(adr: String = String.random().lowercased(), name: String = String.random()) -> MCOAddress{
        return MCOAddress.init(displayName: name, mailbox: adr.lowercased())
    }
    
    func createPGPUser(adr: String = String.random().lowercased(), name: String = String.random()) -> (MCOAddress, String){
        let user = createUser(adr: adr, name: name)
        let id = pgp.generateKey(adr: user.mailbox)
        return (user, id)
    }
    
    func owner() -> (MCOAddress, String){
        Logger.logging = false
        let (user, userid) = createPGPUser(adr: userAdr, name: userName)
        UserManager.storeUserValue(userAdr as AnyObject, attribute: Attribute.userAddr)
        UserManager.storeUserValue(userid as AnyObject, attribute: Attribute.prefSecretKeyID)
        return (user, userid)
    }
    
    func testArrivingMail(){
        let sender = createUser()
        let folder = "INBOX"
        XCTAssertNil( datahandler.findMailAddress(adr: sender.mailbox))
        
        if let mail = testMail(from: sender, to: [user], cc: [user], bcc: [], folder: folder){
            XCTAssertFalse(mail.isSecure)
            XCTAssertFalse(mail.isEncrypted)
            XCTAssertFalse(mail.isSigned)
            XCTAssertFalse(mail.trouble)
            XCTAssertFalse(mail.isCorrectlySigned)
            
            XCTAssert(mail.getCCs().count == 1)
            XCTAssert(mail.getCCs()[0].mailAddress == user.mailbox)
            XCTAssert(mail.getReceivers().count == 1)
            XCTAssert(mail.getReceivers()[0].mailAddress == user.mailbox)
            

            XCTAssertNotNil(datahandler.findMailAddress(adr: sender.mailbox))
            let f = datahandler.findFolder(with: folder)
            XCTAssertEqual(f.mailsOfFolder.count, 1)
            XCTAssertEqual(f.records.count, 1)
            var containsMail = false
            for m in f.mailsOfFolder{
                if m == mail{
                    containsMail = true
                }
            }
            XCTAssertTrue(containsMail)
            var containsAddr = false
            for r in f.records{
                for a  in r.addresses{
                    if a.mailAddress == sender.mailbox {
                        containsAddr = true
                    }
                }
            }
            XCTAssertTrue(containsAddr)
        }
        else {
            XCTFail("No mail")
        }
    }
    
    func testMultiplePlainMailsFromOne() {
        let sender = createUser()
        let n = 100
        let folderName = "INBOX"
        XCTAssertNil(datahandler.findMailAddress(adr: sender.mailbox))
        for _ in 1...n {
            _ = testMail(from: sender, to: [user], cc: [], bcc: [], folder: folderName)
        }
        let folder = datahandler.findFolder(with: folderName)
        XCTAssertEqual(folder.records.count, 1)
        XCTAssertEqual(folder.mailsOfFolder.count, n)
        XCTAssertTrue(checkOrderingOfRecord(record: folder.records.first!))
    }
    
    
    func testMultiplePlainMails() {
        let n = 10
        let m = 10
        let folderName = "INBOX"
        for _ in 1...n {
            let sender = createUser()
            for _ in 1...m {
                _ = testMail(from: sender, to: [user], cc: [], bcc: [], folder: folderName)
            }
        }
        let folder = datahandler.findFolder(with: folderName)
        XCTAssertEqual(folder.records.count, n)
        var prev: KeyRecord?
        for record in folder.records {
            XCTAssertEqual(record.mails.count, m)
            XCTAssertTrue(checkOrderingOfRecord(record: record))
            if let prev = prev {
                XCTAssertTrue(prev < record)
            }
            prev = record
        }
    }
    
    func testMixedMails() {
        let (sender, keyID) = createPGPUser()
        let n = 10
        let senderPGP = SwiftPGP()
        let body = "mixed mails"
        let folderName = "INBOX"
        for _ in 1...n {
            let cryptoObject = senderPGP.encrypt(plaintext: body , ids: [userKeyID], myId: keyID)
            if let encMail = testMail(from: sender, to: [user], cc: [], bcc: [], folder: folderName, cryptoObject: cryptoObject),
                let plainMail = testMail(from: sender, to: [user], cc: [], bcc: []) {
                XCTAssertTrue(encMail.isSecure && encMail.isSigned && encMail.isCorrectlySigned && encMail.isEncrypted && encMail.signedKey?.keyID == keyID)
                XCTAssertTrue(encMail.body == body)
                XCTAssertTrue(encMail.from.mailAddress == plainMail.from.mailAddress && encMail.from.primaryKey?.keyID == plainMail.from.primaryKey?.keyID)
                XCTAssertTrue(plainMail.from.hasKey)
            } else {
                XCTFail("No mails")
            }
        }
        let folder = datahandler.findFolder(with: folderName)
        XCTAssertEqual(folder.records.count, 2)
        var secureRecord = false
        var insecureRecord = false
        for record in folder.records {
            XCTAssertEqual(record.mails.count, n)
            if record.isSecure {
                secureRecord = true
                XCTAssertTrue(record.keyID == keyID)
            }
            else {
                insecureRecord = true
            }
        }
        XCTAssertTrue(secureRecord)
        XCTAssertTrue(insecureRecord)
    }
    
    func testNewKey() {
        let (sender, keyID1) = createPGPUser()
        let senderPGP = SwiftPGP()
        let body = "mixed mails"
        let folderName = "INBOX"
        
        let cryptoObject1 = senderPGP.encrypt(plaintext: body , ids: [userKeyID], myId: keyID1)
        _ = testMail(from: sender, to: [user], cc: [], bcc: [], folder: folderName, cryptoObject: cryptoObject1)
        
        let keyID2 = pgp.generateKey(adr: sender.mailbox, new: true)
        let cryptoObject2 = senderPGP.encrypt(plaintext: body , ids: [userKeyID], myId: keyID2)
        _ = testMail(from: sender, to: [user], cc: [], bcc: [], folder: folderName, cryptoObject: cryptoObject2)

        let folder = datahandler.findFolder(with: folderName)

        XCTAssertEqual(folder.records.count, 2)
        for record in folder.records {
            XCTAssertTrue(record.isSecure)
            XCTAssertTrue(record.keyID == keyID1 || record.keyID == keyID2)
        }
        
        let cryptoObject3 = senderPGP.encrypt(plaintext: body , ids: [userKeyID], myId: keyID1)
        if let oldKeyMail = testMail(from: sender, to: [user], cc: [], bcc: [], folder: folderName, cryptoObject: cryptoObject3){
            XCTAssertTrue(oldKeyMail.isSecure)
        }
    }
    
    func testOwnRecord(){
        let (sender, keyID) = createPGPUser()
        let body = "enc with old key"
        let folderName = "INBOX"
        let oldID = userKeyID
       
        var myrecord = datahandler.getKeyRecord(addr: userAdr, keyID: datahandler.prefSecretKey().keyID)
        XCTAssertEqual(myrecord.keyID, userKeyID)
        XCTAssertEqual(myrecord.ezContact.records.count, 1)

        
        let cryptoObject1 = pgp.encrypt(plaintext: body , ids: [oldID], myId: keyID)
        _ = testMail(from: sender, to: [user], cc: [], bcc: [], folder: folderName, cryptoObject: cryptoObject1)
        let myContact = datahandler.getContactByAddress(userAdr)
        
        if let newKeyIDs = try? pgp.importKeys(key: CryptoTests.importKey, pw: CryptoTests.importPW, isSecretKey: true, autocrypt: false), let newKeyId = newKeyIDs.first {
            _ = datahandler.newSecretKey(keyID: newKeyId, addPk: true)
            XCTAssertTrue(newKeyId == datahandler.prefSecretKey().keyID)
            XCTAssertTrue(userKeyID != newKeyId)
            
            let key = datahandler.findSecretKey(keyID: datahandler.prefSecretKey().keyID!)
            XCTAssertNotNil(key)
            XCTAssertTrue(key?.keyID == newKeyId)
            
            myrecord = datahandler.getKeyRecord(addr: userAdr, keyID: datahandler.prefSecretKey().keyID)
            
            
            XCTAssertEqual(myrecord.keyID, newKeyId)
            XCTAssertEqual(myrecord.ezContact.records.count, 2)
            XCTAssertTrue(myrecord.isSecure)
            XCTAssertEqual(myContact.publicKeys.count, 2)
            let cryptoObject2 = pgp.encrypt(plaintext: body , ids: [newKeyId], myId: keyID )
            let decryptObject2 = pgp.decrypt(data: cryptoObject2.chiphertext!, decryptionIDs: [newKeyId], verifyIds: [keyID], fromAdr: sender.mailbox)

            _ = testMail(from: sender, to: [user], cc: [], bcc: [], folder: folderName, cryptoObject: decryptObject2)
            
            let cryptoObject3 = pgp.encrypt(plaintext: body , ids: [oldID], myId: keyID)
            let decryptObject3 = pgp.decrypt(data: cryptoObject3.chiphertext!, decryptionIDs: [oldID], verifyIds: [keyID], fromAdr: sender.mailbox)
            let oldMail = testMail(from: sender, to: [user], cc: [], bcc: [], folder: folderName, cryptoObject: decryptObject3)
            
            XCTAssertTrue((oldMail?.decryptedWithOldPrivateKey)!)
            
        
        } else {
            XCTFail("No new key")
            return
        }
    }
    
    
    func checkOrderingOfRecord(record: KeyRecord) -> Bool{
        var prev: PersistentMail?
        for m in record.mails{
            if let prev = prev {
                if prev.date < m.date {
                    return false
                }
            }
            prev = m
        }
        return true
    }
    
    func testMail(from: MCOAddress, to: [MCOAddress], cc: [MCOAddress], bcc: [MCOAddress], flags: MCOMessageFlag = MCOMessageFlag.init(rawValue: 0), folder: String = "INBOX" , date: Date = Date(timeIntervalSince1970: TimeInterval(arc4random())), cryptoObject: CryptoObject? = nil, body: String = String.random(length: 20)) -> PersistentMail?{
        
        let subject = String.random(length: 20)
        let id = UInt64(arc4random())
        var body = body
        
        if let decryptedBody = cryptoObject?.decryptedText {
            body = decryptedBody
        }
        var mail: PersistentMail?
        mail = datahandler.createMail(id, sender: from, receivers: to, cc: cc, time: date, received: true, subject: subject, body: body, flags: flags, record: nil, autocrypt: nil, decryptedData: cryptoObject, folderPath: folder, secretKey: nil)
        XCTAssertNotNil(mail)
        XCTAssertEqual(mail?.body, body)
        XCTAssertEqual(mail?.subject, subject)
        XCTAssertEqual(mail?.folder.name.lowercased(), folder.lowercased())
        
        return mail
    }
}
