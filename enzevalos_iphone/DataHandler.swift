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

//TODO: TO Felder mit Strings
// KeyRecord mergen?? IMAP Snyc?


class DataHandler {
    static let handler: DataHandler = DataHandler()
    
    private var managedObjectContext: NSManagedObjectContext
    lazy var mails: [Mail] = self.readMails()
    lazy var contacts: [EnzevalosContact] = self.getContacts()
    lazy var currentstate: State = self.getCurrentState()
    
    private let MaxRecords = 50
    private let MaxMailsPerRecord = 10
    
    var receiverRecords: [KeyRecord]
    
    var maxUID:UInt64 {
        get {
            return currentstate.maxUID
        }
    }
    
    var countMails:Int{
        get {
            return readMails().count
        }
    }
    
    var countContacts: Int {
        get {
            return getContacts().count
        }
    }
    
    func cleanCache() {
        for m in mails {
            managedObjectContext.deleteObject(m)
        }
        for c in contacts {
            managedObjectContext.deleteObject(c)
        }
        mails.removeAll()
        contacts.removeAll()
        currentstate.maxUID = 1
        save()
    }
    
    init() {
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = NSBundle.mainBundle().URLForResource("enzevalos_iphone", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.managedObjectContext.persistentStoreCoordinator = psc
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let docURL = urls[urls.endIndex-1]
        /* The directory the application uses to store the Core Data store file.
         This code uses a file named "DataModel.sqlite" in the application's documents directory.
         */
        let storeURL = docURL.URLByAppendingPathComponent("enzevalos_iphone.sqlite")
        do {
            try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        } catch {
            fatalError("Error migrating store: \(error)")
        }
        receiverRecords = [KeyRecord] ()
        receiverRecords = self.getRecords()
    }
    
    func terminate() {
        cleanContacts()
        cleanMails()
        save()
    }
    
    func save() -> Bool {
        var succ = false
        do{
            try managedObjectContext.save()
            succ = true
        } catch{
            fatalError("Failure to save context\(error)")
        }
        return succ
    }
    
    private func cleanContacts() {
        if countContacts > MaxRecords {
            for _ in  0...(countContacts - MaxRecords) {
                let c = contacts.last! as EnzevalosContact
                if  !c.hasKey{
                    for m in c.from{
                            managedObjectContext.deleteObject(m as NSManagedObject)
                            if let index = mails.indexOf(m) {
                                mails.removeAtIndex(index)
                            }
                        }
                    contacts.removeLast()
                    managedObjectContext.deleteObject(c)
                }
            }
            receiverRecords = getRecords()
        }
    }
    
    private func cleanMails() {
        for c in contacts {
            while c.from.count > MaxMailsPerRecord {
                let last = c.from.last!
                print("delete \(last.uid) of \(last.from.address)")
                managedObjectContext.deleteObject(last)
                save()
                if let index = mails.indexOf(last) {
                        mails.removeAtIndex(index)
                }
            }
        }
    }
    
    
    // Save, load, search
    
    private func find(entityName: String, type:String, search: String) -> [AnyObject]?{
        let fReq: NSFetchRequest = NSFetchRequest(entityName: entityName)
        fReq.predicate = NSPredicate(format:"\(type) CONTAINS '\(search)' ")
        let result: [AnyObject]?
        do {
            result = try self.managedObjectContext.executeFetchRequest(fReq)
        } catch _ as NSError {
            result = nil
            return nil
        }
        return result
    }
    
    private func findNum (entityName: String, type:String, search: UInt64) -> [AnyObject]?{
        let fReq: NSFetchRequest = NSFetchRequest(entityName: entityName)
        fReq.predicate = NSPredicate(format:"\(type) = %D ",search)
        let result: [AnyObject]?
        do {
            result = try self.managedObjectContext.executeFetchRequest(fReq)
        } catch _ as NSError{
            result = nil
            return nil
        }
        return result
    }

    
    private func findAll(entityName:String)->[AnyObject]? {
        let fReq: NSFetchRequest = NSFetchRequest(entityName: entityName)
        let result: [AnyObject]?
        do {
            result = try self.managedObjectContext.executeFetchRequest(fReq)
        } catch _ as NSError {
            result = nil
            return nil
        }
        return result
    }
    
    // -------- Handle mail addresses ---------
    func getMailAddress(address: String)-> Mail_Address {
        let search  = find("Mail_Address", type: "address", search: address)
        var mail_address: Mail_Address
        if search == nil || search!.count == 0 {
            mail_address =  NSEntityDescription.insertNewObjectForEntityForName("Mail_Address",inManagedObjectContext: managedObjectContext) as! Mail_Address
            mail_address.address = address
            mail_address.prefer_encryption = false
        }
        else {
            mail_address = search![0] as! Mail_Address
        }
        return mail_address
    }
    
    func getMailAddressByMCOAddress(address: MCOAddress) -> Mail_Address {
        return getMailAddress(address.mailbox!)
    }
    
    func getMailAddressesByMCOAddresses(addresses: [MCOAddress])->[Mail_Address] {
        var mailaddresses = [Mail_Address]()
        for adr in addresses{
            mailaddresses.append(getMailAddressByMCOAddress(adr))
        }
        return mailaddresses
    }
    
    
    // -------- Start Access to contact(s) --------
    // Find one or a list of enzevalos contacts
    // By mail-address via String or MCOAddress
    // If no enzevalos contact exists. One is created.
    
    func getContactByAddress(address: String) -> EnzevalosContact {
        // Core function
        for c in contacts {
            if c.addresses != nil {
                for adr in c.addresses!{
                    let a = adr as! MailAddress
                    if a.mailAddress ==  address {
                        return c
                    }
                }
            }
            if let cnContact = c.cnContact {
                for adr in cnContact.emailAddresses {
                    let name = adr.value as! String
                    if name == address {
                        let adr = getMailAddress(address)
                        c.addToAddresses(adr)
                        adr.contact = c
                        return c
                    }
                }
            }
        }
        
        let search = find("EnzevalosContact", type: "addresses", search: address)
        var contact: EnzevalosContact
        if search == nil || search!.count == 0 {
            contact = NSEntityDescription.insertNewObjectForEntityForName("EnzevalosContact", inManagedObjectContext: managedObjectContext) as! EnzevalosContact
            contact.displayname = address
            let adr = getMailAddress(address)
            contact.addToAddresses(adr)
            adr.contact = contact
            contacts.append(contact)
        }
        else {
            contact = search! [0] as! EnzevalosContact
            contacts.append(contact)
        }
        return contact
    }
    
    
    func getContact(name: String, address: String, key: String, prefer_enc: Bool) -> EnzevalosContact {
        let contact = getContactByAddress(address)
        contact.displayname = name
        contact.getAddress(address)?.keyID = key
        contact.getAddress(address)?.prefer_encryption //TODO IOptimize: look for Mail_Address and than for contact!
        return contact
    }
 

    
    func getContacts(receivers: [MCOAddress]) -> [EnzevalosContact] {
        var contacts = [EnzevalosContact]()
        var contact: EnzevalosContact
        for r in receivers{
            contact = getContactByMCOAddress(r)
            contacts.append(contact)
        }
        return contacts
    }
    
    func getContactByMCOAddress(address: MCOAddress) -> EnzevalosContact {
        let contact =  getContactByAddress(address.mailbox!)
        if address.displayName != nil {
            contact.displayname = address.displayName
        }
        return contact
    }
    // -------- End Access to contact(s) --------
    
    
    // -------- Start handle to, cc, from addresses --------
    private func handleFromAddress(sender: MCOAddress, fromMail: Mail, autocrypt: AutocryptContact?) {
        let adr: Mail_Address
        let contact = getContactByMCOAddress(sender)
        adr = contact.getAddressByMCOAddress(sender)!
        if let ac = autocrypt{
            adr.prefEnc = ac.prefer_encryption
            adr.encryptionType = ac.type
        }
        fromMail.from = adr
    }
    
    private func handleToAddresses(receivers: [MCOAddress], mail: Mail) {
        mail.addToTo(NSSet(array: getMailAddressesByMCOAddresses(receivers)))
    }
    
    private func handleCCAddresses(cc: [MCOAddress], mail: Mail) {
        mail.addToCc(NSSet(array: getMailAddressesByMCOAddresses(cc)))
    }
    
    // TODO: handle BCC
    
    // -------- End handle to, cc, from addresses --------
    
    func createMail(uid: UInt64, sender: MCOAddress, receivers: [MCOAddress], cc: [MCOAddress], time: NSDate, received: Bool, subject: String, body: String, flags: MCOMessageFlag, record: KeyRecord?, autocrypt: AutocryptContact?) -> Mail {
        
        let finding = findNum("Mail", type: "uid", search: uid)
        let mail: Mail
        
        if finding == nil || finding!.count == 0 {
            // create new mail object
            mail  = NSEntityDescription.insertNewObjectForEntityForName("Mail", inManagedObjectContext: managedObjectContext) as! Mail
          
            mail.body = body
            mail.date = time
            mail.subject = subject
            
            mail.uid = uid
            
            mail.flag = flags
            
            mail.isSigned = false
            mail.isEncrypted = false
            mail.trouble = false

            handleFromAddress(sender, fromMail: mail, autocrypt: autocrypt)
            handleToAddresses(receivers, mail: mail)
            handleCCAddresses(cc, mail: mail)
            
            mail.unableToDecrypt = false
            mail.decryptIfPossible()
        }
        else {
            return finding![0] as! Mail
        }
            
        save()
        if getCurrentState().maxUID < mail.uid {
            getCurrentState().maxUID = mail.uid
        }
        mails.append(mail)
        
        var added = false
        if let r = record{
           added =  r.addNewMail(mail)
        }
        if !added{
            addToReceiverRecords(mail)
        }
       
        
        return mail
    }

    private func readMails() -> [Mail] {
        var mails = [Mail]()
        let result = findAll("Mail")
        if result != nil {
            for r in result! {
                let m = r as! Mail
                mails.append(m)
                if  getCurrentState().maxUID < m.uid {
                    getCurrentState().maxUID = m.uid
                }
            }
        }
        return mails
    }
    
    private func getAddresses()-> [MailAddress]{
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
    
    private func getContacts()->[EnzevalosContact] {
        var contacts = [EnzevalosContact]()
        let result = findAll("EnzevalosContact")
        if result != nil {
            for r in result!{
                let c = r as! EnzevalosContact
                let ms = c.from
                if ms.count > 0 {
                    contacts.append(c)
                }
            }
        }
        return contacts
    }
    
    private func getRecords() -> [KeyRecord] {
        var records = [KeyRecord]()
        let mails = readMails()
        for m in mails {
            addToRecords(m,records: &records)
        }
        for r in records {
            r.mails.sortInPlace()
        }
        records.sortInPlace()
        return records
    }
    
    private func addToRecords(m:Mail, inout records: [KeyRecord] ){
    
        var found = false
        for r in records {
            if r.addNewMail(m) {
                found = true
                records.sortInPlace()
                break
            }
        }
        if !found {
            let r = KeyRecord(mail: m)
            records.append(r)
            records.sortInPlace()
        }
    }
    
    private func addToReceiverRecords(m: Mail){
        addToRecords(m, records: &receiverRecords)
    }
    
    
    func getCurrentState() -> State {
        let result = findAll("State")
        if result != nil && result?.count > 0 {
            currentstate =  (result?.first as? State)!
        }
        else {
            currentstate  = (NSEntityDescription.insertNewObjectForEntityForName("State", inManagedObjectContext: managedObjectContext) as? State)!
            currentstate.currentContacts = contacts.count
            currentstate.currentMails = mails.count
            currentstate.maxUID = 1
            save()
        }
        return currentstate
    }
}
