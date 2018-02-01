//
//  CoreDataTests.swift
//  enzevalos_iphoneTests
//
//  Created by Oliver Wiese on 30.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import XCTest

@testable import enzevalos_iphone
class CoraDataTests: XCTestCase {
    let datahandler = DataHandler.handler
    let pgp = SwiftPGP()

    let userAdr = "alice@example.com"
    let userName = "alice"
    
    
    /*
     Testcases:
     One plain mail, one encrypted mail
     multiple plain mails form one adr, multiple encryted mails from one adr, multiple enc + plain mails from one adr
     plain mails from different adr, enc mails from different adr, enc+plain mails from different adr
     One EnzContact with multi adr/keys
     One adr with different keys
     
     Own ID
     
     Overview Enzcontacts, adr
     
 */
    func testCreateFirstPlainMail(){
        datahandler.reset()
        let senderAdr = "bob@example.com"
        let sender = MCOAddress.init(displayName: "Bob", mailbox: senderAdr)
        let receiverAdr = userAdr
        let receiver = MCOAddress.init(displayName: userName, mailbox: receiverAdr)
        let flags = MCOMessageFlag.answered
        let folder = "folder"
    
        XCTAssertNil(datahandler.findMailAddress(adr: senderAdr))
        XCTAssertNil(datahandler.findMailAddress(adr: receiverAdr))
        XCTAssertTrue(datahandler.allFolders.count <= 1)
        let preMails = datahandler.allMailsInFolder(key: nil, contact: nil, folder: nil, isSecure: false)
        XCTAssertTrue(preMails.count == 0)
        
        let mail = testMail(from: sender!, to: [receiver!], cc: [], bcc: [], flags: flags, folder: folder)
        XCTAssertEqual(datahandler.findFolder(with: folder).counterMails,1)
        XCTAssertNotNil(mail)
        
        
        XCTAssertNotNil(datahandler.findMailAddress(adr: receiverAdr))
        if let mailAdr = datahandler.findMailAddress(adr: receiverAdr){
            let receiverContact = datahandler.getContactByAddress(receiverAdr)
            testEnzContact(enzContact: receiverContact, addresses: [mailAdr], from: [], to: [mail!], cc: [], bcc: [], keys: [])
            testMailAdr(mailAdr: mailAdr, hasKey: false, adr: receiverAdr, ezContact: receiverContact, primaryKey: nil, keys: [])
        }
        
        XCTAssertNotNil(datahandler.findMailAddress(adr: senderAdr))
        if let mailAdr = datahandler.findMailAddress(adr: senderAdr){
            let senderContact = datahandler.getContactByAddress(senderAdr)
            testEnzContact(enzContact: senderContact, addresses: [mailAdr], from: [mail!], to: [], cc: [], bcc: [], keys: [])
            testMailAdr(mailAdr:mailAdr, hasKey: false, adr: senderAdr, ezContact: senderContact, primaryKey: nil, keys: [])
        }
    }
    
    func testCreateMultipleMailsFromOne(){
        datahandler.reset()

        let senderAdr = String.random(length: 36).lowercased()
        let senderName = String.random()
        let sender = MCOAddress.init(displayName: senderName, mailbox: senderAdr)
        
        let user = MCOAddress.init(displayName: userName, mailbox: userAdr)
        let folder = String.random()
        let numberOfMails = 100
        
        var mails = [PersistentMail]()
        for _ in 1...numberOfMails{
            let flag = MCOMessageFlag.answered
            if let mail = testMail(from: sender!, to: [user!], cc: [], bcc: [], flags: flag, folder: folder){
                mails.append(mail)
                print(mail.from.mailAddress)
            }
            
        }
        XCTAssertEqual(datahandler.findFolder(with: folder).counterMails, numberOfMails)
     
        XCTAssertNotNil(datahandler.findMailAddress(adr: userAdr))
        if let mailAdr = datahandler.findMailAddress(adr: userAdr){
            let receiverContact = datahandler.getContactByAddress(userAdr)
            testEnzContact(enzContact: receiverContact, addresses: [mailAdr], from: [], to: mails, cc: [], bcc: [], keys: [])
            testMailAdr(mailAdr: mailAdr, hasKey: false, adr: userAdr, ezContact: receiverContact, primaryKey: nil, keys: [])
        }
        XCTAssertNotNil(datahandler.findMailAddress(adr: (sender?.mailbox)!))
        if let mailAdr = datahandler.findMailAddress(adr: (sender?.mailbox)!){
            let senderContact = datahandler.getContactByAddress((sender?.mailbox)!)
            testEnzContact(enzContact: senderContact, addresses: [mailAdr], from: mails, to: [], cc: [], bcc: [], keys: [])
            testMailAdr(mailAdr:mailAdr, hasKey: false, adr: (sender?.mailbox)!, ezContact: senderContact, primaryKey: nil, keys: [])
        }
    }
    
    func testCreateEncMails(){
        let pgp = SwiftPGP()
        let senders = createSender(n: 1)
        let (user, userid) = createUser(adr: userAdr, name: userName)!
        var mails = [MCOAddress:[PersistentMail]] ()
        
        
        for (sender, id) in senders{
            mails[sender] = [PersistentMail]()
            for _ in 1...20{
                let message = String.random(length: 1000)
                let cryptoObj = pgp.encrypt(plaintext: message, ids: [userid], myId: id)
                
                let folder = String.random()
                if let mail = testMail(from: sender, to: [user], cc: [], bcc: [], flags: MCOMessageFlag.answered, folder: folder, date: Date(), cryptoObject: cryptoObj){
                    mails[sender]?.append(mail)
                }
            }
            //let enzContact = datahandler.getContactByAddress(sender.mailbox)
            //let key = datahandler.findKey(keyID: id)
            //XCTAssertNotNil(key?.mailaddress)
            //if let addrs = key?.mailaddress{
              //  XCTAssertEqual(addrs.count, 1)
            //}
            //XCTAssertEqual(enzContact.displayname, datahandler.getContact(keyID: id)?.displayname)
            //XCTAssertTrue(enzContact.from.count == mails[sender]?.count)
            //let records = enzContact.records
            //XCTAssertLessThan(records.count, 2)
            //XCTAssertGreaterThan(records.count, 0)
            
            
            
            
            
        }
        // Testen: #Mails, Zuordnung zu sicherem Kontakt. In einem Keyrecord? #Keyrecords pro Kontakt.
        
        
        
    }
    
    func createUser(adr: String, name: String) -> (MCOAddress, String)?{
        let id = pgp.generateKey(adr: adr.lowercased())

        if let user = MCOAddress.init(displayName: adr.lowercased(), mailbox: name){
            return (user, id)
        }
        return nil
    }
    
    func createSender(n: Int)-> [MCOAddress:String]{
        var result = [MCOAddress:String]()
        
        for _ in 1...n{
            let adr = String.random()
            let name = String.random()
            
            if let (mcoaddr, id) =  createUser(adr: adr, name: name){
                result[mcoaddr] = id
            }
        }
        return result
    }

    
    
   
    
    
    func testMail(from: MCOAddress, to: [MCOAddress], cc: [MCOAddress], bcc: [MCOAddress], flags: MCOMessageFlag, folder: String , date: Date = Date(), cryptoObject: CryptoObject? = nil) -> PersistentMail?{
        let subject = String.random(length: 20)
        let body = String.random(length: 1000)
       
        let id = UInt64(arc4random())
        
        let preMails = datahandler.allMailsInFolder(key: nil, contact: nil, folder: nil, isSecure: false)
        
        var mail: PersistentMail?
        if cryptoObject != nil{
            mail = datahandler.createMail(id, sender: from, receivers: to, cc: cc, time: date, received: true, subject: subject, body: nil, flags: flags, record: nil, autocrypt: nil, decryptedData: cryptoObject, folderPath: folder, secretKey: nil)
        }
        else{
            mail = datahandler.createMail(id, sender: from, receivers: to, cc:cc, time: date, received: true, subject: subject, body: body, flags: flags, record: nil, autocrypt: nil, decryptedData: nil, folderPath: folder, secretKey: nil)
        }
        
        XCTAssertNotNil(mail)
        let allMails = datahandler.allMailsInFolder(key: nil, contact: nil, folder: nil, isSecure: false)
        XCTAssertEqual(allMails.count, preMails.count + 1)
        var found = false
        for m in allMails{
            if mail?.uid == m.uid{
                found = true
                XCTAssertEqual(m.body,body)
                XCTAssertEqual(m.subject, subject)
                XCTAssertEqual(m.date, date)
                break
            }
        }
        XCTAssertTrue(found)
        return mail
    }
    
    
    func testMailAdr(mailAdr: Mail_Address, hasKey: Bool, adr: String, ezContact: EnzevalosContact, primaryKey: PersistentKey?, keys: [PersistentKey]){
        XCTAssertEqual(mailAdr.hasKey, hasKey)
        XCTAssertEqual(mailAdr.mailAddress, adr)
        XCTAssertEqual(mailAdr.contact, ezContact)
        if hasKey{
            XCTAssertNotNil(mailAdr.primaryKey)
            XCTAssertEqual(mailAdr.primaryKey?.keyID, primaryKey?.keyID)
            XCTAssertEqual(mailAdr.keys.count, keys.count)
            for key in keys{
                var found = false
                for k in mailAdr.keys{
                    if k.keyID == key.keyID{
                        found = true
                        break
                    }
                }
                XCTAssertFalse(found)
                // Same size && For all k in keys: k in mailAdr.keys -> mailAdr.keys == keys
            }
        }
        else{
            XCTAssertNil(mailAdr.primaryKey)
            XCTAssertEqual(mailAdr.keys.count ,0)
        }
    }
    
    func testEnzContact(enzContact: EnzevalosContact, addresses: [MailAddress], from: [PersistentMail], to: [PersistentMail], cc: [PersistentMail], bcc: [PersistentMail], keys: [PersistentKey]){
        // Check addresses
        XCTAssertEqual(enzContact.addresses.count, addresses.count)
        for adr in addresses{
            var found = false
            for a in enzContact.addresses{
                if let myadr = a as? Mail_Address{
                    if adr.mailAddress == myadr.mailAddress{
                        found = true
                        break
                    }
                }
               
            }
            XCTAssertTrue(found)
        }
        
        // Check mails (from, cc, to)
        XCTAssertEqual(enzContact.from.count, from.count)
        for m in from{
            XCTAssertTrue(enzContact.from.contains(m))
        }
        
        XCTAssertEqual(enzContact.to.count, to.count)
        for m in to{
            XCTAssertTrue(enzContact.to.contains(m))
        }
        
        XCTAssertEqual(enzContact.cc.count, cc.count)
        for m in cc{
            XCTAssertTrue(enzContact.cc.contains(m))
        }
        
        XCTAssertEqual(enzContact.bcc.count, bcc.count)
        for m in bcc{
            XCTAssertTrue(enzContact.bcc.contains(m))
        }
        
        // Check Crypto
        if keys.count == 0{
            XCTAssertFalse(enzContact.hasKey)
            XCTAssertTrue(enzContact.publicKeys.count == 0)
            for a in enzContact.addresses{
                if let adr = a as? Mail_Address{
                    XCTAssertFalse(adr.hasKey)
                }
            }
        }
        else{
            XCTAssertTrue(enzContact.hasKey)
            XCTAssertEqual(enzContact.publicKeys.count, keys.count)
            for key in keys{
                var found = false
                for mykey in enzContact.publicKeys{
                    if key.keyID == mykey.keyID{
                        found = true
                        break
                    }
                }
                XCTAssertTrue(found)
            }
            for a in enzContact.addresses{
                if let adr = a as? Mail_Address{
                    for key in adr.keys{
                        var found = false
                        for mykey in enzContact.publicKeys{
                            if key.keyID == mykey.keyID{
                                found = true
                                break
                            }
                        }
                        XCTAssertTrue(found)
                    }
                }
            }
        }
        
        // Check records
        XCTAssertEqual(enzContact.records.count, keys.count + 1)
        for key in keys{
            var found = false
            for record in enzContact.records{
                if record.keyID == key.keyID{
                    found = true
                }
            }
            XCTAssertTrue(found)
        }
        for record in enzContact.records{
            testKeyRecord(record: record)
        }
    }
    
    func testKeyRecord(record: KeyRecord){
        XCTAssertTrue(record.addresses.count > 0)
        //XCTAssertTrue(record.mails.count > 0) We have to consider self keyrecord...
        // Test if mails are sorted!
        
        if record.isSecure{
            XCTAssertNotNil(record.keyID)
            for mail in record.mails{
                XCTAssertTrue(mail.isSecure)
            }
            let mails =  DataHandler.handler.allMailsInFolder(key: record.keyID, contact: nil, folder: record.folder, isSecure: record.isSecure)
            XCTAssertEqual(record.mails.count, mails.count)
            for m in mails{
                XCTAssertTrue(record.mails.contains(m))
            }
        }
        else{
            for mail in record.mails{
                XCTAssertFalse(mail.isSecure)
            }
        }
        let mails =  DataHandler.handler.allMailsInFolder(key: record.keyID, contact: record.ezContact, folder: record.folder, isSecure: record.isSecure)
        XCTAssertEqual(record.mails.count, mails.count)
        for m in mails{
            XCTAssertTrue(record.mails.contains(m))
        }
        
        if let keyId = record.keyID{
            for adr in record.addresses{
                var found = false
                for key in adr.keys{
                    if key.keyID == keyId{
                        found = true
                    }
                }
                XCTAssertTrue(found)
            }
            var found = false
            for key in record.ezContact.publicKeys{
                if key.keyID == keyId{
                    found = true
                }
            }
            XCTAssertTrue(found)
            
            XCTAssertTrue(keyId == record.fingerprint!)
            XCTAssertTrue(keyId == record.pgpKey?.keyID.longIdentifier)
            XCTAssertTrue(keyId == record.storedKey?.keyID)
        }
        else{
            XCTAssertNil(record.fingerprint)
            XCTAssertNil(record.pgpKey)
            XCTAssertNil(record.storedKey)
        }
        
    }
}
