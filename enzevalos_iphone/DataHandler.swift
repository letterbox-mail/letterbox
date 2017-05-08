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
            managedObjectContext.delete(m)
        }
        for c in contacts {
            managedObjectContext.delete(c)
        }
        mails.removeAll()
        contacts.removeAll()
        currentstate.maxUID = 1
        save()
    }
    
    init() {
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = Bundle.main.url(forResource: "enzevalos_iphone", withExtension:"momd") else {
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
        let docURL = urls[urls.endIndex-1]
        /* The directory the application uses to store the Core Data store file.
         This code uses a file named "DataModel.sqlite" in the application's documents directory.
         */
        let storeURL = docURL.appendingPathComponent("enzevalos_iphone.sqlite")
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
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
    
    func save(){
        do{
            try managedObjectContext.save()
        } catch{
            fatalError("Failure to save context\(error)")
        }
    }
    
    private func cleanContacts() {
        if countContacts > MaxRecords {
            for _ in  0...(countContacts - MaxRecords) {
                let c = contacts.last! as EnzevalosContact
                if  !c.hasKey{
                    for m in c.from{
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
                print("delete \(last.uid) of \(last.from.address)")
                managedObjectContext.delete(last)
                save()
                if let index = mails.index(of: last) {
                        mails.remove(at: index)
                }
            }
        }
    }
    
    
    // Save, load, search
    
    private func find(_ entityName: String, type:String, search: String) -> [AnyObject]?{
        let fReq: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName) //FIXME: NSFetchRequestResult richtig hier?
        fReq.predicate = NSPredicate(format:"\(type) CONTAINS '\(search)' ")
        let result: [AnyObject]?
        do {
            result = try self.managedObjectContext.fetch(fReq)
        } catch _ as NSError {
            result = nil
            return nil
        }
        return result
    }
    
    private func findNum (_ entityName: String, type:String, search: UInt64) -> [AnyObject]?{
        let fReq: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName) //FIXME: NSFetchRequestResult richtig hier?
        fReq.predicate = NSPredicate(format:"\(type) = %D ",search)
        let result: [AnyObject]?
        do {
            result = try self.managedObjectContext.fetch(fReq)
        } catch _ as NSError{
            result = nil
            return nil
        }
        return result
    }

    
    private func findAll(_ entityName:String)->[AnyObject]? {
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
    
    
    
    // -------- Handle mail addresses ---------
    func getMailAddress(_ address: String, temporary: Bool)-> MailAddress {
        let search  = find("Mail_Address", type: "address", search: address)
        if search == nil || search!.count == 0 {
            if temporary{
                return CNMailAddressExtension(addr: address as NSString)
            }
            else{
                let mail_address =  NSEntityDescription.insertNewObject(forEntityName: "Mail_Address",into: managedObjectContext) as! Mail_Address
                mail_address.address = address
                mail_address.prefer_encryption = false
                return mail_address
            }
        }
        else {
            return search![0] as! Mail_Address
        }
    }
    
    func getMailAddressesByString(_ addresses: [String], temporary: Bool) -> [MailAddress]{
        var mailaddresses = [MailAddress]()
        for adr in addresses{
            mailaddresses.append(getMailAddress(adr, temporary: temporary))
        }
        return mailaddresses    
    }
    
    func getMailAddressByMCOAddress(_ address: MCOAddress, temporary: Bool) -> MailAddress {
        return getMailAddress(address.mailbox!, temporary: temporary)
    }
    
    func getMailAddressesByMCOAddresses(_ addresses: [MCOAddress])->[Mail_Address] {
        var mailaddresses = [Mail_Address]()
        for adr in addresses{
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
        for c in contacts {
            if c.addresses != nil {
                for adr in c.addresses!{
                    let a = adr as! MailAddress
                    if a.mailAddress ==  lowerAdr {
                        return c
                    }
                }
            }
            if let cnContact = c.cnContact {
                for adr in cnContact.emailAddresses {
                    let name = adr.value as String
                    if name == lowerAdr {
                        let adr = getMailAddress(lowerAdr, temporary: false) as! Mail_Address
                        c.addToAddresses(adr)
                        adr.contact = c
                        return c
                    }
                }
            }
        }
        
        let search = find("EnzevalosContact", type: "addresses", search: lowerAdr)
        var contact: EnzevalosContact
        if search == nil || search!.count == 0 {
            contact = NSEntityDescription.insertNewObject(forEntityName: "EnzevalosContact", into: managedObjectContext) as! EnzevalosContact
            contact.displayname = lowerAdr
            let adr = getMailAddress(lowerAdr, temporary: false)as! Mail_Address
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
        for r in receivers{
            contact = getContactByMCOAddress(r)
            contacts.append(contact)
        }
        return contacts
    }
    
    func getContactByMCOAddress(_ address: MCOAddress) -> EnzevalosContact {
        let contact =  getContactByAddress(address.mailbox!)
        if address.displayName != nil {
            contact.displayname = address.displayName
        }
        return contact
    }
    // -------- End Access to contact(s) --------
    
    
    // -------- Start handle to, cc, from addresses --------
    private func handleFromAddress(_ sender: MCOAddress, fromMail: Mail, autocrypt: AutocryptContact?) {
        let adr: Mail_Address
        let contact = getContactByMCOAddress(sender)
        adr = contact.getAddressByMCOAddress(sender)!
        if let ac = autocrypt{
            adr.prefEnc = ac.prefer_encryption
            adr.encryptionType = ac.type
        }
        fromMail.from = adr
    }
    
    private func handleToAddresses(_ receivers: [MCOAddress], mail: Mail) {
        mail.addToTo(NSSet(array: getMailAddressesByMCOAddresses(receivers)))
    }
    
    private func handleCCAddresses(_ cc: [MCOAddress], mail: Mail) {
        mail.addToCc(NSSet(array: getMailAddressesByMCOAddresses(cc)))
    }
    
    // TODO: handle BCC
    
    // -------- End handle to, cc, from addresses --------
    
    func createMail(_ uid: UInt64, sender: MCOAddress, receivers: [MCOAddress], cc: [MCOAddress], time: Date, received: Bool, subject: String, body: String, flags: MCOMessageFlag, record: KeyRecord?, autocrypt: AutocryptContact?) -> Mail {
        
        let finding = findNum("Mail", type: "uid", search: uid)
        let mail: Mail
        
        if finding == nil || finding!.count == 0 {
            // create new mail object
            mail  = NSEntityDescription.insertNewObject(forEntityName: "Mail", into: managedObjectContext) as! Mail
          
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
            r.mails.sort()
        }
        records.sort()
        print("#KeyRecords: \(records.count) ")
        print("#Mails: \(mails.count)")
        for r in records{
            r.showInfos()
        }
        return records
    }
    
    private func addToRecords(_ m:Mail, records: inout [KeyRecord] ){
    
        var found = false
        for r in records {
            if r.addNewMail(m) {
                found = true
                records.sort()
                break
            }
        }
        if !found {
            let r = KeyRecord(mail: m)
            mergeRecords(newRecord: r, records: &records)
            records.append(r)
            records.sort()
        }
    }
    
    
    private func mergeRecords(newRecord: KeyRecord, records: inout[KeyRecord]){
        var j = 0
        if !newRecord.hasKey{
            return
        }
        while j < records.count{
            let r = records[j]
            if !r.hasKey && r.ezContact == newRecord.ezContact{
                var i = 0
                while i < r.mails.count{
                    let mail = r.mails[i]
                    var remove = false
                    if mail.from.keyID == newRecord.key{
                        remove = newRecord.addNewMail(mail)
                        if remove{
                            r.mails.remove(at: i)
                        }
                    }
                    if !remove{
                        i = i + 1
                    }
                }
                if r.mails.count == 0{
                    records.remove(at: j)
                } else{
                    j = j + 1
                }
            } else{
                j = j + 1
            }
        }
    }
    
    private func addToReceiverRecords(_ m: Mail){
        addToRecords(m, records: &receiverRecords)
    }
    
    
    func getCurrentState() -> State {
        let result = findAll("State")
        if result != nil && result?.count > 0 {
            currentstate =  (result?.first as? State)!
        }
        else {
            currentstate  = (NSEntityDescription.insertNewObject(forEntityName: "State", into: managedObjectContext) as? State)!
            currentstate.currentContacts = contacts.count
            currentstate.currentMails = mails.count
            currentstate.maxUID = 1
            save()
        }
        return currentstate
    }
}
