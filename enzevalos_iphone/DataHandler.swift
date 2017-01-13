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

class DataHandler: NSObject {
    private static var handler: DataHandler? = nil

    private var managedObjectContext: NSManagedObjectContext
    private var mails: [Mail]
    private var isLoadMails: Bool
    private var contacts: [EnzevalosContact]
    private var isLoadContacts: Bool
    private var currentstate: State?
    private var isLoadState: Bool
    
    private let MaxRecords = 10
    private let MaxMailsPerRecord = 20
    
    
    
    override  init() {
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
        mails = [Mail]()
        isLoadMails = false
        contacts = [EnzevalosContact]()
        isLoadContacts = false
        isLoadState = false
        print("Finish init of DataHandler")
    }
    
    static func getDataHandler()->DataHandler{
        if handler == nil{
            handler = DataHandler.init()
        }
        return handler!
    }
    
    func terminate(){
        cleanContacts()
        cleanMails()
        save()
    }
    
    func save()->Bool{
        var succ = false
        do{
            try getContextManager().save()
            succ = true
        } catch{
            fatalError("Failure to save context\(error)")
        }
        return succ
    }
    
    
    private func cleanContacts(){
        if countedContacts() > MaxRecords{
            var contacts = getContacts()
            var cm: Int
            cm = 0
            for _ in  0...(countedContacts() - MaxRecords){
                let c = contacts.removeLast()
                if c.from != nil{
                    for m in c.from!{
                        getContextManager().deleteObject(m as! NSManagedObject)
                        cm += 1
                    }
                    c.from = nil
                }
                getContextManager().deleteObject(c)
            }
            isLoadMails = false
            
        }
        isLoadContacts = false
        isLoadMails = false
    }
    
    
    private func cleanMails(){
        if countedMails() > (MaxMailsPerRecord * countedContacts()) {
            for c in getContacts() {
                if let ms = c.from{
                    if ms.count > MaxMailsPerRecord{
                        for _ in  0...(ms.count - MaxMailsPerRecord){
                            let last = ms.firstObject as! Mail
                            c.removeFromFrom(last)
                            getContextManager().deleteObject(last)
                        }
                    }
                }
            }
        
        }
        isLoadContacts = false
        isLoadMails = false
    }
    
    func countedMails()->Int{
        return readMails().count
    }
    
    func countedContacts()-> Int{
        return getContacts().count
    }
    
    // Save, load, search
    
    
    func getContextManager() -> NSManagedObjectContext{
        return managedObjectContext
    }
    
    private func find(entityName: String, type:String, search: String) -> [AnyObject]?{
        let fReq: NSFetchRequest = NSFetchRequest(entityName: entityName)
        fReq.predicate = NSPredicate(format:"\(type) CONTAINS '\(search)' ")
        let result: [AnyObject]?
        do {
            result = try self.managedObjectContext.executeFetchRequest(fReq)
        } catch _ as NSError{
            result = nil
            return nil
        }
        return result
    }
    
    private func findAll(entityName:String)->[AnyObject]?{
        let fReq: NSFetchRequest = NSFetchRequest(entityName: entityName)
       // fReq.sortDescriptors = [NSSortDescriptor(key: "from", ascending: false)]
        let result: [AnyObject]?
        do {
            result = try self.managedObjectContext.executeFetchRequest(fReq)
        } catch _ as NSError{
            result = nil
            return nil
        }
        return result
    }
    // -------- Handle mail addresses ---------
    
    func getMailAddress(address: String)-> Mail_Address{
        let search  = find("Mail_Address", type: "address", search: address)
        var mail_address: Mail_Address
        if(search == nil || search!.count == 0){
            mail_address =  NSEntityDescription.insertNewObjectForEntityForName("Mail_Address",inManagedObjectContext: managedObjectContext) as! Mail_Address
            mail_address.address = address
            mail_address.key = ""
            mail_address.prefer_encryption = false
        }
        else{
            mail_address = search! [0] as! Mail_Address
        }
        return mail_address
    }
    
    func getMailAddressByMCOAddress(address: MCOAddress)->Mail_Address{
        return getMailAddress(address.mailbox!)
    }
    
    func getMailAddressesByMCOAddresses(addresses: [MCOAddress])->[Mail_Address]{
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
    
    func getContactByAddress(address: String) -> EnzevalosContact{
        // Core function
        for c in contacts{
            if c.addresses != nil{
                for adr in c.addresses!{
                    let a = adr as! MailAddress
                    if a.mailAddress ==  address{
                        return c
                    }
                }
            }
        }
        
        let search = find("EnzevalosContact", type: "addresses", search: address)
        var contact: EnzevalosContact
        if (search == nil || search!.count == 0){
            contact = NSEntityDescription.insertNewObjectForEntityForName("EnzevalosContact", inManagedObjectContext: managedObjectContext) as! EnzevalosContact
            contact.displayname = address
            let adr = getMailAddress(address)
            contact.addToAddresses(adr)
            adr.contact = contact
            contacts.append(contact)
        }
        else{
            contact = search! [0] as! EnzevalosContact
            contacts.append(contact)
        }
        return contact
    }

    
    func getContact(name: String, address: String, key: String, prefer_enc: Bool)->EnzevalosContact{
        let contact = getContactByAddress(address)
        contact.displayname = name
        contact.getAddress(address)?.key = key
        contact.getAddress(address)?.prefer_encryption //TODO IOptimize: look for Mail_Address and than for contact!
        return contact
    }
    
    func getContacts(receivers: [MCOAddress])-> [EnzevalosContact]{
        var contacts = [EnzevalosContact]()
        var contact: EnzevalosContact
        for r in receivers{
            contact = getContactByMCOAddress(r)
            contacts.append(contact)

        }
        return contacts
    }
    
    func getContactByMCOAddress(address: MCOAddress)-> EnzevalosContact{
        let contact =  getContactByAddress(address.mailbox!)
        if(address.displayName != nil){
            contact.displayname = address.displayName
        }
        return contact
    }
    // -------- End Access to contact(s) --------
    
    
    // -------- Start handle to, cc, from addresses --------
    private func handleFromAddress(sender: MCOAddress, fromMail: Mail){
        let contact = getContactByMCOAddress(sender)
        contact.addToFrom(fromMail)
        let adr: Mail_Address
        adr = contact.getAddressByMCOAddress(sender)!
        fromMail.addFrom(adr)

    }
    
    private func handleToAddresses(receivers: [MCOAddress], mail: Mail)
    {
        let contacts = getContacts(receivers)
        for c in contacts{
            c.addToTo(mail)
        }
        mail.addReceivers(getMailAddressesByMCOAddresses(receivers))
    }
    
    private func handleCCAddresses(cc: [MCOAddress], mail: Mail)
    {
        let contacts = getContacts(cc)
        for c in contacts{
            c.addToCc(mail)
        }
        mail.addCC(getMailAddressesByMCOAddresses(cc))
    }
    
    // TODO: handle BCC
    
    // -------- End handle to, cc, from addresses --------

    func createMail(uid: UInt64, sender: MCOAddress, receivers: [MCOAddress], cc: [MCOAddress], time: NSDate, received: Bool, subject: String, body: String, flags: MCOMessageFlag)-> Mail{
        
        let finding = find("Mail", type: "uid", search: String(uid))
        let mail: Mail
        
        
        
        if(finding == nil || finding!.count == 0){
           // create new mail object
            mail  = NSEntityDescription.insertNewObjectForEntityForName("Mail", inManagedObjectContext: managedObjectContext) as! Mail
            /*
            if(isEncrypted) {
                mail.body =  decryptedBody
            }
            else{
                mail.body = body
            }
 */
            mail.body = body
            mail.date = time
            mail.subject = subject
           
            mail.uid = uid

            mail.setFlags(flags)
            
            mail.isSigned = false
            mail.isEncrypted = false
            mail.trouble = false
            mail.unableToDecrypt = true

        }
        else{
            return finding![0] as! Mail
        }
        handleFromAddress(sender, fromMail: mail)
        handleToAddresses(receivers, mail: mail)
        handleCCAddresses(cc, mail: mail)
        
        save()
        if getCurrentState().getMaxUid() < mail.uid{
            getCurrentState().setMaxUid(mail.uid)
        }
        mails.append(mail)
        return mail
    }
    
    
    
    private func loadMails(){
        mails = [Mail]()
        let result = findAll("Mail")
        if(result != nil){
            for r in result!{
                let m = r as! Mail
                mails.append(m)
                if  getCurrentState().getMaxUid() < m.uid{
                    getCurrentState().setMaxUid(m.uid)
                }
            }
        }
        isLoadMails = true
    }
    
    func readMaxUid()->UInt64{
        let state = getCurrentState()
        let max = state.getMaxUid()
        return  max
    }
    
    private func readMails()->[Mail]{
        if(!isLoadMails){
            loadMails()
        }
        return mails
    }
    
    private func loadContacts(){
        contacts = [EnzevalosContact]()
        let result = findAll("EnzevalosContact")
        if(result != nil){
            for r in result!{
                let c = r as! EnzevalosContact
                if let ms = c.from{
                    if(ms.count > 0){
                        contacts.append(c)
                    }
                }
            }
        }
        isLoadContacts = true
    }
    
    func getContacts()->[EnzevalosContact]{
        if !isLoadContacts {
            loadContacts()
        }
        return contacts
    }
    
    
    func getRecords()->[KeyRecord]{
        var records = [KeyRecord] ()
        let mails = readMails()
        for m in mails {
            var found = false
            for r in records {
                if r.updateMails(m){
                    found = true
                    break
                }
            }
            if !found {
                records.append(KeyRecord(mail: m))
            }
        }
        
        for r in records {
            r.mails.sortInPlace()
        }
        
        records.sortInPlace()
        return records
    }
    
    func getCurrentState()->State{
        if !isLoadState {
            let result = findAll("State")
            if(result != nil && result?.count > 0){
                currentstate =  result?.first as? State
            }
            else{
                currentstate  = NSEntityDescription.insertNewObjectForEntityForName("State", inManagedObjectContext: managedObjectContext) as? State
                currentstate!.setNumberOfContacts(getContacts().count)
                currentstate!.setNumberOfMails(readMails().count)
                currentstate!.setMaxUid(1)
                save()
            }
            isLoadState = true
        }
        return currentstate!
    
    }
    
    
    
    
}
