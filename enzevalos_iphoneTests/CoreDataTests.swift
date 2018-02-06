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
      Test Inbox
         - #records
         - #Sortierung, #Mails
     Test EnzContact
     - #records
     
     test getMethods. ala: getContact, get MailAddr etc
     
 */
    func testFirstPlainMail(){
        datahandler.reset()
        let senderAdr = "bob@example.com"
        let sender = MCOAddress.init(displayName: "Bob", mailbox: senderAdr)
        let receiverAdr = userAdr
        let receiver = MCOAddress.init(displayName: userName, mailbox: receiverAdr)
        let flags = MCOMessageFlag.answered
        let folder = "folder"
    
        XCTAssertNil(datahandler.findMailAddress(adr: senderAdr))
        //XCTAssertNil(datahandler.findMailAddress(adr: receiverAdr))
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
    
    
 
    
    func testMultiplePlainMails(){
        datahandler.reset()
        let (user, id) = createPGPUser()
        let sender = createUser()
        let mails = sendMails(sender: sender, user: user, userID: id)
        
        XCTAssertNotNil(datahandler.findMailAddress(adr: user.mailbox))
        if let mailAdr = datahandler.findMailAddress(adr: user.mailbox){
            let receiverContact = datahandler.getContactByAddress(user.mailbox)
            testEnzContact(enzContact: receiverContact, addresses: [mailAdr], from: [], to: mails, cc: [], bcc: [], keys: [])
            testMailAdr(mailAdr: mailAdr, hasKey: false, adr: user.mailbox, ezContact: receiverContact, primaryKey: nil, keys: [])
        }
    }
    
    func testMultiEncMails(){
        sendMultiEncMails(sameFolder: false)
    }
    
    func testSimpleFolderRecords(){
        sendMultiEncMails(sameFolder: true)
    }
    
    func sendMultiEncMails(sameFolder: Bool){
        datahandler.reset()
        let senders = createSender(n: 2)
        let (user, userid) = owner()
        
        let folder = String.random()
        var allMails = [MCOAddress:Set<PersistentMail>] ()

        for (sender, id) in senders{
            if sameFolder{
                allMails[sender] = sendMails(sender: sender, user: user, userID: userid, numberOfMails: 10, folder: folder)
                let (ms, key) = sendEncMails(sender: sender, senderID: id, user: user, userID: userid, prevMails: allMails[sender]!, folder: folder)
                allMails[sender] = allMails[sender]?.union(ms)
                for mail in ms{
                    XCTAssertEqual(mail.folder.name, folder)
                }
                let mails = sendMails(sender: sender, user: user, userID: id, numberOfMails: 10, hasKey: true, primaryKey: key!, keys: [key!], previousMails: allMails[sender]!, folder: folder)
                allMails[sender] = allMails[sender]?.union(mails)

            }
            else{
                allMails[sender] = sendMails(sender: sender, user: user, userID: userid, numberOfMails: 10)
                let (ms, key) = sendEncMails(sender: sender, senderID: id, user: user, userID: userid, prevMails: allMails[sender]!)
                allMails[sender] = allMails[sender]?.union(ms)
                let mails = sendMails(sender: sender, user: user, userID: id, numberOfMails: 10, hasKey: true, primaryKey: key!, keys: [key!], previousMails: allMails[sender]!)
                allMails[sender] = allMails[sender]?.union(mails)
            }
        }
        if sameFolder{
            let f = datahandler.findFolder(with: folder)
            for (sender, id) in senders{
                let mykey = datahandler.findKey(keyID: id)
                for mail in allMails[sender]!{
                    XCTAssertEqual(mail.folder.name, folder)
                    XCTAssertEqual(mail.folder, f)
                    if mail.folder != f{
                        print("Not in folder!")
                        XCTAssert(false)
                    }
                    if let mailKey = mail.signedKey{
                        XCTAssertEqual(mail.keyID, mykey?.keyID)
                        XCTAssertEqual(mail.keyID, id)
                        XCTAssertEqual(mail.keyID, mailKey.keyID)
                        
                    }
                    XCTAssertEqual(mail.from.mailAddress, sender.mailbox)
                }
            }
            
            //TODO: check keys in folder (siehe datanhandler)
            let folderKeys = datahandler.allKeysInFolder(folder: f)
            XCTAssertEqual(folderKeys.count, senders.count)
            
            print("My keys in folder: \(folderKeys.count)")
            XCTAssertEqual(f.records.count, senders.count * 2)
            print(f.records.count)
            for r in f.records{
                print(r.mails.count)
                print(r.addresses.count)
            }
            for mails in allMails.values{
                for mail in mails{
                    if mail.folder.name != folder{
                        print("ERROR!!!")
                    }
                    XCTAssertEqual(mail.folder.name, folder)
                }
            }
        }
    }
    
    func testKeyRecords(){
        testMultiKeys()
        let folders = datahandler.allFolders
        var inbox: Folder
        
        for folder in folders{
            if let mails = folder.mails{
                
            }
        }
        
        // Testen: Records sind nicht leer
        
        // add new mail
        
    }
    
    func testOwnRecord(){
        // teste, ob alle eigenen Keys da sind
        
        // teste, ob das hin und herspringen klappt.
    }
    
    
    
    func testMultiKeys(){
        datahandler.reset()
        let sender = createPGPUser()
        let user = owner()
        let n = 1 // number of keys
        
        var allMails = Set<PersistentMail>()
        var keys = Set<PersistentKey>()
        var lastKey: PersistentKey?
        var primKey: PersistentKey?
        var newMails = Set<PersistentMail>()
        
        let folder = String.random()

        allMails = sendMails(sender: sender.0, user: user.0, userID: user.1, folder: folder)
        (newMails, lastKey) = sendEncMails(sender: sender.0, senderID: sender.1, user: user.0, userID: user.1, prevMails: allMails, folder: folder)
        allMails = newMails.union(allMails)
        primKey = lastKey
        if let key = lastKey{
            keys.insert(key)
        }
        for _ in 1...n{
            let sender2 = createPGPUser(adr: sender.0.mailbox, name: sender.0.displayName)
            newMails = sendMails(sender: sender.0, user: user.0, userID: user.1, hasKey: true, primaryKey: primKey, keys: Array(keys),previousMails: allMails, folder: folder)
            allMails = newMails.union(allMails)
            (newMails, lastKey) = sendEncMails(sender: sender2.0, senderID: sender2.1, user: user.0, userID: user.1, prevMails: allMails, keys: keys, folder : folder)
            allMails = newMails.union(allMails)
            primKey = lastKey
            if let key = lastKey{
                keys.insert(key)
            }
        }
        // Test contact with focus on multiple pks
        let enzContact = datahandler.getContactByAddress(sender.0.mailbox)
        let mailAdr = datahandler.getMailAddress(sender.0.mailbox, temporary: false)

        XCTAssertEqual(enzContact.publicKeys.count, keys.count)
        testEnzContact(enzContact: enzContact, addresses: [mailAdr], from: allMails, to: [], cc: [], bcc: [], keys: Array(keys))
        for key in keys{
            let keyContact = datahandler.getContact(keyID: key.keyID)
            XCTAssertEqual(keyContact, enzContact)
        }
        // Test mail adr with focus on multiple pks and prim key
        XCTAssertEqual(mailAdr.publicKeys.count, keys.count)
        XCTAssertEqual(mailAdr.primaryKey?.keyID, primKey?.keyID)
        testMailAdr(mailAdr: mailAdr as! Mail_Address, hasKey: true, adr: sender.0.mailbox, ezContact: enzContact, primaryKey: primKey, keys: Array(keys))
        // Test key records -> folders?
        for m in allMails{
            XCTAssertEqual(m.folder.name, folder)
        }
        let f = datahandler.findFolder(with: folder)
        let records = datahandler.folderRecords(folderPath: folder)
        XCTAssertEqual(records.count, keys.count + 1)
        XCTAssertEqual(f.records.count, keys.count + 1)
        var counterInsecureRecords = 0
        var countMails = 0
        for record in f.records{
            if record.isSecure{
                var found = false
                for key in keys{
                    if key.keyID == record.keyID{
                        found = true
                        break
                    }
                }
                XCTAssertTrue(found)
            }
            else{
                counterInsecureRecords = counterInsecureRecords + 1
            }
            countMails = countMails +  record.mails.count
            
        }
        XCTAssertEqual(counterInsecureRecords, 1)
        XCTAssertEqual(countMails, allMails.count)
    }
    
    func sendMails(sender: MCOAddress, user: MCOAddress, userID: String,  numberOfMails: Int = 10, hasKey: Bool = false, primaryKey: PersistentKey? = nil , keys: [PersistentKey] = [], previousMails: Set<PersistentMail> = Set<PersistentMail>(), folder: String = String.random()) -> Set<PersistentMail>{
        var mails = Set<PersistentMail>()
        
        for _ in 1...numberOfMails{
            let flag = MCOMessageFlag.answered
            if let mail = testMail(from: sender, to: [user], cc: [], bcc: [], flags: flag, folder: folder){
                mails.insert(mail)
            }
            
        }
        var mailCounter = numberOfMails
        for m in previousMails{
            if m.folder.name == folder{
                mailCounter =  mailCounter + 1
            }
        }
       // XCTAssertEqual(datahandler.findFolder(with: folder).counterMails, mailCounter)
        XCTAssertNotNil(datahandler.findMailAddress(adr: (sender.mailbox)!))
        if let mailAdr = datahandler.findMailAddress(adr: (sender.mailbox)!){
            let allMails = previousMails.union(mails)
            let senderContact = datahandler.getContactByAddress((sender.mailbox)!)
            testEnzContact(enzContact: senderContact, addresses: [mailAdr], from: allMails, to: [], cc: [], bcc: [], keys:keys)
            testMailAdr(mailAdr:mailAdr, hasKey: hasKey, adr: (sender.mailbox)!, ezContact: senderContact, primaryKey: primaryKey, keys: keys)
        }
        return mails
    }
    
    func sendEncMails(sender: MCOAddress, senderID: String, user: MCOAddress, userID: String, prevMails: Set<PersistentMail>, keys: Set<PersistentKey> = Set<PersistentKey>(), primKey: PersistentKey? = nil, folder: String = String.random()) -> (Set<PersistentMail>, PersistentKey?){
        var mails = Set<PersistentMail>()
        var key: PersistentKey?
        var primaryKey: PersistentKey?
        var firstmail: PersistentMail?
        var mykeys = keys
        if let k = primKey{
            primaryKey = k
        }
        
        for _ in 1...10{
            let message = String.random(length:  10)
            let chipher = pgp.encrypt(plaintext: message, ids: [userID], myId: senderID)
            
            let plain = pgp.decrypt(data: chipher.chiphertext!, decryptionId: userID, verifyIds: [senderID], fromAdr: sender.mailbox)
            if let mail = testMail(from: sender, to: [user], cc: [], bcc: [], flags: MCOMessageFlag.answered, folder: folder, date: Date(), cryptoObject: plain, isSecure: true, message: message){
                let k  = datahandler.newPublicKey(keyID: senderID, cryptoType: .PGP, adr: sender.mailbox, autocrypt: false, firstMail: mail, newGenerated: false)
                if key == nil{
                    key = k
                    firstmail = mail
                    primaryKey = k
                    mykeys.insert(k)
                }
                let k2 = datahandler.findKey(keyID: k.keyID)
                let f = datahandler.findFolder(with: folder)
                for m in f.mails!{
                    if let mail = m as? PersistentMail{
                        if mail.keyID == k2?.keyID{
                            print("k in mail in folder!")
                        }
                    }
                }
                let keys = datahandler.allKeysInFolder(folder: f)
                for myKey in keys{
                    if myKey == k2?.keyID{
                        print("k in keys of folder! \(myKey)")
                    }
                }
                mails.insert(mail)
            }
        }
        let enzContact = datahandler.getContactByAddress(sender.mailbox)
        key = datahandler.findKey(keyID: senderID)
        XCTAssertNotNil(key?.mailaddress)
        if let addrs = key?.mailaddress{
            XCTAssertEqual(addrs.count, 1)
            for a in addrs{
                if let addr = a as? Mail_Address{
                    XCTAssertEqual(addr.address, sender.mailbox)
                    XCTAssertEqual(addr.primaryKey?.keyID, primaryKey?.keyID)
                    XCTAssertEqual(addr.primaryKey?.firstMail?.subject, firstmail?.subject)
                }
            }
        }
        let allMails = prevMails.union(mails)
        XCTAssertEqual(enzContact, datahandler.getContact(keyID: senderID))
        XCTAssertEqual(enzContact.from.count, allMails.count)
            
        let records = enzContact.records
        XCTAssertEqual(records.count, mykeys.count + 1)
        
        
        return (mails, key)
    }
    // Testen: #Mails, Zuordnung zu sicherem Kontakt. In einem Keyrecord? #Keyrecords pro Kontakt.
    
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
    
    func createSender(n: Int)-> [MCOAddress:String]{
        var result = [MCOAddress:String]()
        
        for _ in 1...n{
            let adr = String.random()
            let name = String.random()
            
            let (mcoaddr, id) =  createPGPUser(adr: adr, name: name)
            result[mcoaddr] = id
        }
        return result
    }

    
    
   
    
    
    func testMail(from: MCOAddress, to: [MCOAddress], cc: [MCOAddress], bcc: [MCOAddress], flags: MCOMessageFlag, folder: String , date: Date = Date(), cryptoObject: CryptoObject? = nil, isSecure: Bool = false, message: String? = nil) -> PersistentMail?{
        let subject = String.random(length: 20)
        var body = String.random(length: 20)
        
        if let m = message{
            body = m
        }
        let id = UInt64(arc4random())
        var preMails = Set<PersistentMail>()
        var ms = datahandler.allMailsInFolder(key: nil, contact: nil, folder: nil, isSecure: false)
        preMails = preMails.union(ms)
        ms = datahandler.allMailsInFolder(key: nil, contact: nil, folder: nil, isSecure: true)
        preMails = preMails.union(ms)

        var mail: PersistentMail?
        
        if cryptoObject != nil{
            mail = datahandler.createMail(id, sender: from, receivers: to, cc: cc, time: date, received: true, subject: subject, body: nil, flags: flags, record: nil, autocrypt: nil, decryptedData: cryptoObject, folderPath: folder, secretKey: nil)
        }
        else{
            mail = datahandler.createMail(id, sender: from, receivers: to, cc:cc, time: date, received: true, subject: subject, body: body, flags: flags, record: nil, autocrypt: nil, decryptedData: nil, folderPath: folder, secretKey: nil)
        }
        XCTAssertNotNil(mail)
        let f = datahandler.findFolder(with: folder)
        if let m = mail{
            f.updateRecords(mail: m)
        }
        var allMails = Set<PersistentMail>()
        ms = datahandler.allMailsInFolder(key: nil, contact: nil, folder: nil, isSecure: false)
        allMails = allMails.union(ms)
        ms = datahandler.allMailsInFolder(key: nil, contact: nil, folder: nil, isSecure: true)
        allMails = allMails.union(ms)
        
   
        XCTAssertEqual(allMails.count, preMails.count + 1)
        var found = false
        for m in allMails{
            if mail?.uid == m.uid{
                found = true
                if isSecure{
                    XCTAssertEqual(m.decryptedBody,body)
                }
                else{
                    XCTAssertEqual(m.body, body)
                }
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
            XCTAssertEqual(mailAdr.publicKeys.count, keys.count)
            for key in keys{
                var found = false
                for k in mailAdr.publicKeys{
                    if k.keyID == key.keyID{
                        found = true
                        break
                    }
                }
                XCTAssertTrue(found)
                // Same size && For all k in keys: k in mailAdr.keys -> mailAdr.keys == keys
            }
        }
        else{
            XCTAssertNil(mailAdr.primaryKey)
            XCTAssertEqual(mailAdr.publicKeys.count ,0)
        }
    }
    
    func testEnzContact(enzContact: EnzevalosContact, addresses: [MailAddress], from: Set<PersistentMail>, to: Set<PersistentMail>, cc: Set<PersistentMail>, bcc: Set<PersistentMail>, keys: [PersistentKey]){
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
                    for key in adr.publicKeys{
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
                for key in adr.publicKeys{
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
            //XCTAssertTrue(keyId == record.fingerprint!)
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
