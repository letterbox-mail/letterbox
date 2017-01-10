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
    
    private let MaxRecords = 50
    private let MaxMails = 50
    
    
    
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
        save()
    }
    
    private func save()->Bool{
        var succ = false
        do{
            try getContextManager().save()
            succ = true
        } catch{
            fatalError("Failure to save context\(error)")
        }
        return succ
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
    
    
    
    
    
    // -------- Start Access to contact(s) --------
    // Find one or a list of enzevalos contacts
    // By mail-address via String or MCOAddress
    // If no enzevalos contact exists. One is created.
    
    func getContactByAddress(address: String) -> EnzevalosContact{
        // Core function
        let search = find("EnzevalosContact", type: "addresses", search: address)
        var contact: EnzevalosContact
        if (search == nil || search!.count == 0){
            contact = NSEntityDescription.insertNewObjectForEntityForName("EnzevalosContact", inManagedObjectContext: managedObjectContext) as! EnzevalosContact
            contact.update(address)
            let adr = getMailAddress(address)
            contact.addToAddresses(adr)
            adr.contact = contact
        }
        else{
            contact = search! [0] as! EnzevalosContact
        }
        return contact
    }

    
    func getContact(name: String, address: String, key: String, prefer_enc: Bool)->EnzevalosContact{
        let contact = getContactByAddress(address)
        contact.update(name)
        contact.getAddress(address)?.key = key
        contact.getAddress(address)?.prefer_encryption //TODO IOptimize: look for Mail_Address and than for contact!
        save()
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
            contact.setDisplayName(address.displayName)
        }
        return contact
    }
    // -------- End Access to contact(s) --------
    
    
    // -------- Start handle to, cc, from addresses --------
    private func handleFromAddress(sender: MCOAddress, fromMail: Mail){
        let contact = getContactByMCOAddress(sender)
        contact.addFromMail(fromMail)
        let adr: Mail_Address
        adr = contact.getAddressByMCOAddress(sender)!
        fromMail.addFrom(adr)

    }
    
    private func handleToAddresses(receivers: [MCOAddress], mail: Mail)
    {
        let contacts = getContacts(receivers)
        for c in contacts{
            c.addToMail(mail)
        }
       // TODO mail.addReceivers(contacts)
    }
    
    private func handleCCAddresses(cc: [MCOAddress], mail: Mail)
    {
        let contacts = getContacts(cc)
        for c in contacts{
            c.addCCMail(mail)
        }
        //TODO ERROR HIER: Fix-> Überprüfung mit Datenlayout
      // mail.addCC(contacts)
    }
    
    // TODO: handle BCC
    
    // -------- End handle to, cc, from addresses --------

    func createMail(uid: UInt64, sender: MCOAddress, receivers: [MCOAddress], cc: [MCOAddress], time: NSDate, received: Bool, subject: String, body: String, decryptedBody: String?, isEncrypted: Bool, isVerified: Bool, trouble: Bool, flags: MCOMessageFlag)-> Mail{
        
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
            mail.isEncrypted = isEncrypted

            mail.isRead = flags.contains(MCOMessageFlag.Seen)
            mail.uid = NSDecimalNumber.init(unsignedLongLong: uid)

            mail.trouble = trouble

            mail.setFlags(flags)

        }
        else{
            return finding![0] as! Mail
        }
        handleFromAddress(sender, fromMail: mail)
        handleToAddresses(receivers, mail: mail)
        // TODO FIX handleCCAddresses(cc, mail: mail)
        
        save()
        if getCurrentState().getMaxUid() < mail.uid.unsignedLongLongValue{
            getCurrentState().setMaxUid(mail.uid.unsignedLongLongValue)
        }
        mails.append(mail)
        return mail
    }
    
    
    func readMail(mail: Mail)->Bool{
        mail.markMessageAsRead(true)
        save()
        return true
    
    }
    
    func markMailAsUnread(mail:Mail)->Bool{
        mail.markMessageAsRead(false)
        save()
        return true
    }
    
    private func loadMails(){
        mails = [Mail]()
        let result = findAll("Mail")
        if(result != nil){
            for r in result!{
                let m = r as! Mail
                mails.append(m)
                if  getCurrentState().getMaxUid() < m.uid.unsignedLongLongValue{
                    getCurrentState().setMaxUid(m.uid.unsignedLongLongValue)
                }
            }
        }
        isLoadMails = true
    }
    
    func readMaxUid()->UInt64{
        let state = getCurrentState()
        let max = state.getMaxUid()
        print("MaxUid: \(max)")
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
                if(c.getFromMails().count > 0){
                    contacts.append(c)
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
    
    func getContactsWithCNContacts()->[EnzevalosContact]{
        var contacts = getContacts()
        do{
            try AppDelegate.getAppDelegate().contactStore.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: [CNContactFormatter.descriptorForRequiredKeysForStyle(CNContactFormatterStyle.FullName), CNContactEmailAddressesKey, CNContactImageDataKey, CNContactThumbnailImageDataKey]), usingBlock: {
                (let cn : CNContact, let stop) -> Void in
                //                    print(c)
                // Add or not?
                var new: Bool
                new = true
                if cn.emailAddresses.count == 0{
                    return
                }
                for ec in contacts{
                    if let eccn = ec.getContact(){
                        if eccn.identifier == cn.identifier{
                            new = false
                            break
                        }
                    }
                
                }
                if new {
                    var ec: EnzevalosContact
                    ec = EnzevalosContact()
                }
                
            })
        }
        catch {}
        return contacts
    }
    
    
    func getRecords()->[KeyRecord]{
        
        //TODO Fix here!
        
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
            r.showInfos()
        }
        
        records.sortInPlace()
        
        for r in records {
            r.showInfos()
        }
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
