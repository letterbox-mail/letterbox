//
//  DataHandler.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 29/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import UIKit
import CoreData
import Contacts
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


//TODO: TO Felder mit Strings
// KeyRecord mergen?? IMAP Snyc?


class DataHandler {
    static let handler: DataHandler = DataHandler()

    private var managedObjectContext: NSManagedObjectContext

    private let MaxRecords = 50
    private let MaxMailsPerRecord = 100
    
    var allFolders: [Folder]{
        get{
            var folders = [Folder]()
            if let objects = findAll("Folder"){
                for case let folder as Folder in objects{
                    folders.append(folder)
                }
            }
            return folders
        }
    
    }

    
    func callForFolders(done: @escaping ((_ error: Bool) -> ())){ // Maybe call back? Look for new Folder?
        AppDelegate.getAppDelegate().mailHandler.allFolders{ (err, array) -> Void in
            guard err == nil else {
                print("Error while fetching all folders: \(String(describing: err))")
                done(true)
                return
            }
            
            if let newFolders = array{
                for new in newFolders{
                    if case let folder as MCOIMAPFolder = new{
                        let f = self.findFolder(name: folder.path)
                        f.delimiter = folder.delimiter.description
                        f.flags = folder.flags
                    }
                }
            }
            done(false)
        }
    }


    init() {
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = Bundle.main.url(forResource: "enzevalos_iphone", withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.managedObjectContext.persistentStoreCoordinator = psc

        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = urls[urls.endIndex - 1]
        /* The directory the application uses to store the Core Data store file.
         This code uses a file named "DataModel.sqlite" in the application's documents directory.
         */
        let storeURL = docURL.appendingPathComponent("enzevalos_iphone.sqlite")
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        } catch {
            fatalError("Error migrating store: \(error)")
        }
        managedObjectContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType);
        
        callForFolders(done: {_ in return})

    }

    func terminate() {
        save()
    }

    func save() {
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context\(error)")
        }
    }


    private func removeAll(entity: String) {
        let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: entity))
        do {
            try managedObjectContext.execute(DelAllReqVar)
        }
        catch {
            print(error)
        }
    }




    func reset() {
        removeAll(entity: "EnzevalosContact")
        removeAll(entity: "PersistentMail")
        removeAll(entity: "Mail_Address")
        removeAll(entity: "State")
        removeAll(entity: "Folder")
       
    }

    /*
    private func cleanContacts() {
        if countContacts > MaxRecords {
            for _ in 0...(countContacts - MaxRecords) {
                let c = contacts.last! as EnzevalosContact
                if !c.hasKey {
                    for m in c.from {
                        managedObjectContext.delete(m as NSManagedObject)
                        if let index = mails.index(of: m) {
                            mails.remove(at: index)
                        }
                    }
                    contacts.removeLast()
                    managedObjectContext.delete(c)
                }
                }
                receiverRecords = getRecords()
            }
        }

 
        private func cleanMails() {
            for c in contacts {
                while c.from.count > MaxMailsPerRecord {
                    let last = c.from.last!
                    managedObjectContext.delete(last)
                    save()
                    if let index = mails.index(of: last) {
                        mails.remove(at: index)
                    }
                }
            }
        }

*/
        // Save, load, search

        private func find(_ entityName: String, type: String, search: String) -> [AnyObject]? {
            let fReq: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName) //FIXME: NSFetchRequestResult richtig hier?
            fReq.predicate = NSPredicate(format: "\(type) CONTAINS '\(search)' ")
            let result: [AnyObject]?
            do {
                result = try self.managedObjectContext.fetch(fReq)
            } catch _ as NSError {
                result = nil
                return nil
            }
            return result
        }

        private func findNum (_ entityName: String, type: String, search: UInt64) -> [AnyObject]? {
            let fReq: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName) //FIXME: NSFetchRequestResult richtig hier?
            fReq.predicate = NSPredicate(format: "\(type) = %D ", search)
            let result: [AnyObject]?
            do {
                result = try self.managedObjectContext.fetch(fReq)
            } catch _ as NSError {
                result = nil
                return nil
            }
            return result
        }


        private func findAll(_ entityName: String) -> [AnyObject]? {
            let fReq: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName) //FIXME: NSFetchRequestResult richtig hier?
            let result: [AnyObject]?
            do {
                result = try self.managedObjectContext.fetch(fReq)
            } catch _ as NSError {
                result = nil
                return nil
            }
            return result
        }


    func findFolder(name: String) -> Folder{
        if let search = find("Folder", type: "path", search:name){
            if search.count > 0{
                return search[0] as! Folder
            }
        }
        let folder  = NSEntityDescription.insertNewObject(forEntityName: "Folder", into: managedObjectContext) as! Folder
        folder.path = name
        return folder
    }
    
    func existsFolder(with name: String) -> Bool {
        if let search = find("Folder", type: "path", search:name), search.count > 0{
            return true
        }
        return false
    }

        // -------- Handle mail addresses ---------
        func getMailAddress(_ address: String, temporary: Bool) -> MailAddress {
            let search = find("Mail_Address", type: "address", search: address)
            if search == nil || search!.count == 0 {
                if temporary {
                    return CNMailAddressExtension(addr: address as NSString)
                }
                    else {
                        let mail_address = NSEntityDescription.insertNewObject(forEntityName: "Mail_Address", into: managedObjectContext) as! Mail_Address
                        mail_address.address = address
                        mail_address.prefer_encryption = EncState.NOAUTOCRYPT
                        return mail_address
                }
            }
                else {
                    return search![0] as! Mail_Address
            }
        }

        func getMailAddressesByString(_ addresses: [String], temporary: Bool) -> [MailAddress] {
            var mailaddresses = [MailAddress]()
            for adr in addresses {
                mailaddresses.append(getMailAddress(adr, temporary: temporary))
            }
            return mailaddresses
        }

        func getMailAddressByMCOAddress(_ address: MCOAddress, temporary: Bool) -> MailAddress {
            return getMailAddress(address.mailbox!, temporary: temporary)
        }

        func getMailAddressesByMCOAddresses(_ addresses: [MCOAddress]) -> [Mail_Address] {
            var mailaddresses = [Mail_Address]()
            for adr in addresses {
                mailaddresses.append(getMailAddressByMCOAddress(adr, temporary: false) as! Mail_Address)
            }
            return mailaddresses
        }


        // -------- Start Access to contact(s) --------
        // Find one or a list of enzevalos contacts
        // By mail-address via String or MCOAddress
        // If no enzevalos contact exists. One is created.

        func getContactByAddress(_ address: String) -> EnzevalosContact {
            // Core function
            let lowerAdr = address.lowercased()
            if let contacts = find("EnzevalosContact", type: "addresses", search: lowerAdr){
                for c in contacts{
                    if case let contact as EnzevalosContact = c{
                        return contact
                    }
                }
            }
            if let contacts = findAll("EnzevalosContact"){
                for c  in contacts{
                    if case let contact as EnzevalosContact = c{
                        if let cnContact = contact.cnContact{
                            for adr in cnContact.emailAddresses {
                                let name = adr.value as String
                                if name == lowerAdr {
                                    let adr = getMailAddress(lowerAdr, temporary: false) as! Mail_Address
                                    c.addToAddresses(adr)
                                    adr.contact = contact
                                    return contact
                                }
                            }
                        }
                    }
                }
            }
            var contact: EnzevalosContact
            contact = NSEntityDescription.insertNewObject(forEntityName: "EnzevalosContact", into: managedObjectContext) as! EnzevalosContact
            contact.displayname = lowerAdr
            let adr = getMailAddress(lowerAdr, temporary: false) as! Mail_Address
            contact.addToAddresses(adr)
            adr.contact = contact
            return contact
        }


        func getContact(_ name: String, address: String, key: String, prefer_enc: Bool) -> EnzevalosContact {
            let contact = getContactByAddress(address)
            contact.displayname = name
            contact.getAddress(address)?.keyID = key
            _ = contact.getAddress(address)?.prefer_encryption //TODO IOptimize: look for Mail_Address and than for contact!
            return contact
        }

        func getContacts(_ receivers: [MCOAddress]) -> [EnzevalosContact] {
            var contacts = [EnzevalosContact]()
            var contact: EnzevalosContact
            for r in receivers {
                contact = getContactByMCOAddress(r)
                contacts.append(contact)
            }
            return contacts
        }

        func getContactByMCOAddress(_ address: MCOAddress) -> EnzevalosContact {
            let contact = getContactByAddress(address.mailbox!)
            if address.displayName != nil {
                contact.displayname = address.displayName
            }
            return contact
        }
        // -------- End Access to contact(s) --------


        // -------- Start handle to, cc, from addresses --------
        private func handleFromAddress(_ sender: MCOAddress, fromMail: PersistentMail, autocrypt: AutocryptContact?) {
            let adr: Mail_Address
            let contact = getContactByMCOAddress(sender)
            adr = contact.getAddressByMCOAddress(sender)!
            if adr.lastSeen > fromMail.date{
                adr.lastSeen = fromMail.date
            }
            if let ac = autocrypt {
                adr.prefEnc = ac.prefer_encryption
                adr.encryptionType = ac.type
                if adr.lastSeenAutocrypt != nil && adr.lastSeenAutocrypt > fromMail.date{
                    adr.lastSeenAutocrypt = fromMail.date
                }
                else if adr.lastSeenAutocrypt == nil{
                    adr.lastSeenAutocrypt = fromMail.date
                }
                
            }
            else if adr.lastSeen < adr.lastSeenAutocrypt && adr.prefer_encryption != EncState.NOAUTOCRYPT{
                adr.prefer_encryption = EncState.RESET
            }
            fromMail.from = adr
        }

        private func handleToAddresses(_ receivers: [MCOAddress], mail: PersistentMail) {
            mail.addToTo(NSSet(array: getMailAddressesByMCOAddresses(receivers)))
        }

        private func handleCCAddresses(_ cc: [MCOAddress], mail: PersistentMail) {
            mail.addToCc(NSSet(array: getMailAddressesByMCOAddresses(cc)))
        }

        // TODO: handle BCC

        // -------- End handle to, cc, from addresses --------

    func createMail(_ uid: UInt64, sender: MCOAddress?, receivers: [MCOAddress], cc: [MCOAddress], time: Date, received: Bool, subject: String, body: String?, flags: MCOMessageFlag, record: KeyRecord?, autocrypt: AutocryptContact?, decryptedData: DecryptedData?, folder: String = "INBOX") {

            let finding = findNum("PersistentMail", type: "uid", search: uid)
            let mail: PersistentMail

            if finding == nil || finding!.count == 0 {
                // create new mail object
                mail = NSEntityDescription.insertNewObject(forEntityName: "PersistentMail", into: managedObjectContext) as! PersistentMail

                mail.body = body
                mail.date = time
                mail.subject = subject

                mail.uid = uid

                mail.flag = flags

                mail.isSigned = false
                mail.isEncrypted = false
                mail.trouble = false

                if sender != nil{
                    handleFromAddress(sender!, fromMail: mail, autocrypt: autocrypt)
                }
                handleToAddresses(receivers, mail: mail)
                handleCCAddresses(cc, mail: mail)

                mail.unableToDecrypt = false
                if decryptedData == nil{
                    // Maybe PGPInline?
                    // TODO: Refactoring!
                    mail.decryptIfPossible()
                }
                else{
                    let encState: EncryptionState = (decryptedData?.encryptionState)!
                    let signState: SignatureState = (decryptedData?.signatureState)!
                    
                    switch encState {
                    case EncryptionState.NoEncryption:
                        mail.isEncrypted = false
                        mail.trouble = false
                        mail.unableToDecrypt = false
                    case EncryptionState.UnableToDecrypt:
                        mail.unableToDecrypt = true
                        mail.isEncrypted = true
                        mail.trouble = true
                    default:
                        mail.isEncrypted = true
                        mail.trouble = false
                        mail.unableToDecrypt = false
                    }
                    
                    switch signState {
                    case SignatureState.NoSignature:
                        mail.isSigned = false
                    case SignatureState.InvalidSignature:
                        mail.isSigned = true
                        mail.isCorrectlySigned = true
                        mail.trouble = true
                    case SignatureState.ValidSignature:
                        mail.isCorrectlySigned = true
                        mail.isSigned = true
                    }
                    mail.decryptedBody = body
                    print("Mail from \(mail.from.mailAddress) about \(String(describing: mail.subject)) has states: enc: \(mail.isEncrypted) and sign: \(mail.isSigned), correct signed: \(mail.isCorrectlySigned) has troubles:\(mail.trouble) and is secure? \(mail.isSecure) unable to decrypt? \(mail.unableToDecrypt)")
                }
            }
            else {
                return 
            }
        
            let myfolder = findFolder(name: folder) as Folder
            print("DataHAndler around line 455: ", folder)
            myfolder.addToMails(mail)
            if mail.uid > myfolder.maxID{
                myfolder.maxID = mail.uid
            }
            if mail.uid < myfolder.lastID || myfolder.lastID == 1{
                myfolder.lastID = mail.uid
            }


            save()
            if let r = record {
                _ = r.addNewMail(mail)
            }

        }

        private func readMails() -> [PersistentMail] {
            var mails = [PersistentMail]()
            let result = findAll("PersistentMail")
            if result != nil {
                for r in result! {
                    let m = r as! PersistentMail
                    mails.append(m)
                    }
                }
                return mails
            }

        private func getAddresses() -> [MailAddress] {
                var adrs = [MailAddress]()
                let result = findAll("Mail_Address")
                if result != nil {
                    for r in result! {
                        let adr = r as! MailAddress
                        adrs.append(adr)
                    }
                }
                return adrs

            }

        private func getContacts() -> [EnzevalosContact] {
                var contacts = [EnzevalosContact]()
                let result = findAll("EnzevalosContact")
                if result != nil {
                    for r in result! {
                        let c = r as! EnzevalosContact
                        let ms = c.from
                        if ms.count > 0 {
                            contacts.append(c)
                        }
                    }
                }
                return contacts
            }

      

    

    
    func folderRecords(folder: String = "INBOX") -> [KeyRecord]{
        let folder = findFolder(name: folder) as Folder
        return folder.records
    }


    // Can we remove current state???
        func getCurrentState() -> State {
                let result = findAll("State")
                if result != nil && result?.count > 0 {
                    return (result?.first as? State)!
                }
                else {
                    let currentstate = (NSEntityDescription.insertNewObject(forEntityName: "State", into: managedObjectContext) as? State)!
                    if let set = findAll("EnzevalosContact"){
                     currentstate.currentContacts = set.count
                    }
                    else{
                        currentstate.currentContacts = 0
                    }
                    if let set = findAll("Mails"){
                        currentstate.currentMails = set.count
                    }
                    else{
                        currentstate.currentMails = 0
                    }
                    save()
                    return currentstate
                }
            }
        }
