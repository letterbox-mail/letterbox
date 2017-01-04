//
//  DataHandler.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 29/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import UIKit
import CoreData
class DataHandler: NSObject {
    private static var handler: DataHandler? = nil

    private var managedObjectContext: NSManagedObjectContext
    private var maxUid: UInt64
    private var mails: [Mail]
    private var isLoadMails: Bool
    private var contacts: [EnzevalosContact]
    private var isLoadContacts: Bool
    
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
        maxUid = 0
        mails = [Mail]()
        isLoadMails = false
        contacts = [EnzevalosContact]()
        isLoadContacts = false
        
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
    
    func find(entityName: String, type:String, search: String) -> [AnyObject]?{

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
    
    func findAll(entityName:String)->[AnyObject]?{
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
    
    // -------- Start Access to contact(s) --------
    // Find one or a list of enzevalos contacts
    // By mail-address via String or MCOAddress
    // If no enzevalos contact exists. One is created.
    
    func getContactByAddress(address: String) -> EnzevalosContact{
        // Core function
        let search = find("EnzevalosContact", type: "mail_address", search: address)
        var contact: EnzevalosContact
        if (search == nil || search!.count == 0){
            contact = NSEntityDescription.insertNewObjectForEntityForName("EnzevalosContact", inManagedObjectContext: managedObjectContext) as! EnzevalosContact
            contact.setAddress(address)
            contact.update(address, key: "", prefer_enc: false)
        }
        else{
            contact = search! [0] as! EnzevalosContact
        }
        //save()
        return contact
    }

    
    func getContact(name: String, address: String, key: String, prefer_enc: Bool)->EnzevalosContact{
        let contact = getContactByAddress(address)
        contact.update(name, key: key, prefer_enc: prefer_enc)
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
        //save()
        return contact
    }
    // -------- End Access to contact(s) --------
    
    
    // -------- Start handle to, cc, from addresses --------
    private func handleFromAddress(sender: MCOAddress, fromMail: Mail){
        let contact = getContactByMCOAddress(sender)
        contact.addFromMail(fromMail)
        fromMail.addFrom(contact)
    }
    
    private func handleToAddresses(receivers: [MCOAddress], mail: Mail)
    {
        let contacts = getContacts(receivers)
        for c in contacts{
            c.addToMail(mail)
        }
        mail.addReceivers(contacts)
    }
    
    private func handleCCAddresses(cc: [MCOAddress], mail: Mail)
    {
        let contacts = getContacts(cc)
        for c in contacts{
            c.addCCMail(mail)
        }
        mail.addCC(contacts)
    }
    
    // TODO: handle BCC
    
    // -------- End handle to, cc, from addresses --------

    func createMail(uid: Int64, sender: MCOAddress, receivers: [MCOAddress], cc: [MCOAddress], time: NSDate?, received: Bool, subject: String?, body: String?, decryptedBody: String?, isEncrypted: Bool, isVerified: Bool, trouble: Bool, isUnread: Bool, flags: MCOMessageFlag)-> Mail{
        
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
            print("Create new Mail")
            mail.body = body
            mail.date = time
            mail.subject = subject
            mail.isEncrypted = isEncrypted
            mail.isVerified = isVerified
            // TODO: mail.isUnread = isUnread
            mail.uid = uid
            mail.trouble = trouble
            mail.setFlags(flags)
            
        }
        else{
            print ("request old mail")
            return finding![0] as! Mail
        }
        handleFromAddress(sender, fromMail: mail)
        handleToAddresses(receivers, mail: mail)
        handleCCAddresses(cc, mail: mail)
        
        save()
        /*
        if(maxUid < UInt64(mail.uid)){
            maxUid = UInt64(mail.uid)
        }
        mails.append(mail)
 */
        return mail
    }
    
    
    func readMail(mail: Mail)->Bool{
        //TODO: FIX ME
        save()
        return true
    
    }
    
    func markMailAsUnread(mail:Mail)->Bool{
        //TODO: FIX ME
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
                if maxUid < UInt64(m.uid){
                    maxUid = UInt64(m.uid)
                }
            }
        }
        isLoadMails = true
    }
    
    func readMaxUid()->UInt64{
        if !isLoadMails {
            loadMails()
        }
        if mails.count < 20 { //TODO Fix here Init? how many mails schould be loaded???
            print("MaxUID: \(maxUid)-> return 0")
            return 1
        }
        return maxUid
    }
    
    func readMails()->[Mail]{
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
    
}
