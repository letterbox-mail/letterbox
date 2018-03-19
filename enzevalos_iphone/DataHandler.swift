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


fileprivate func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs === rhs || lhs.compare(rhs as Date) == .orderedSame
}

fileprivate func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs as Date) == .orderedAscending

}

//TODO: TO Felder mit Strings
// KeyRecord mergen?? IMAP Snyc?

typealias requestTuple = (request: String, value: Any)

class DataHandler {
    static let handler: DataHandler = DataHandler()

    private var managedObjectContext: NSManagedObjectContext
    private let MaxRecords = 50
    private let MaxMailsPerRecord = 100
    
    var allFolders: [Folder] {
        get {
            var folders = [Folder]()
            if let objects = findAll("Folder") {
                for case let folder as Folder in objects {
                    folders.append(folder)
                }
            }
            return folders
        }
    }

    //All Folders, which are not a subfolder
    var allRootFolders: [Folder] {
        var root: [Folder] = []
        for f in allFolders {
            if !f.path.contains(f.delimiter) {
                root.append(f)
            }
        }
        return root
    }



    func hasMail(folderName: String, uid: UInt64) -> Bool {
        let folder = findFolder(with: folderName)
        // TODO: As  Sql rquest with NSPredicate?
        if let mails = folder.mails {
            for m in mails {
                let mail = m as! PersistentMail
                if mail.uid == uid {
                    return true
                }
            }
        }
        return false
    }


    func callForFolders(done: @escaping ((_ error: Error?) -> ())) { // Maybe call back? Look for new Folder?
        AppDelegate.getAppDelegate().mailHandler.allFolders { (err, array) -> Void in
            guard err == nil else {
                print("Error while fetching all folders: \(String(describing: err))")
                done(err)
                return
            }

            if let newFolders = array {
                for new in newFolders {
                    if case let folder as MCOIMAPFolder = new {
                        let f = self.findFolder(with: folder.path)
                        f.delimiter = String(Character(UnicodeScalar(UInt8(folder.delimiter))))
                        f.flags = folder.flags
                    }
                }
            }
            done(nil)
        }
    }


    func allAddressesInFolder(folder: Folder, withoutSecure: Bool) -> [MailAddress] {
        let fReq = NSFetchRequest<NSFetchRequestResult>(entityName: "PersistentMail")
        let folderPredicate = NSPredicate(format: "folder = %@", folder)
        if withoutSecure {
            fReq.predicate = NSPredicate(format: "folder = %@ AND (isEncrypted = false OR isSigned = false OR unableToDecrypt = true OR trouble = true)", folder)
        }
            else {
                fReq.predicate = folderPredicate
        }
        fReq.resultType = NSFetchRequestResultType.dictionaryResultType
        fReq.propertiesToFetch = ["from"]
        fReq.returnsDistinctResults = true
        var addresses = [MailAddress]()
        let result = (try? self.managedObjectContext.fetch(fReq))

        if let res = result as? Array<NSDictionary> {
            for nsdict in res {
                let value = nsdict.value(forKey: "from")
                if let fromID = value as? NSManagedObjectID {
                    if let adr = managedObjectContext.object(with: fromID) as? Mail_Address {
                        // Exclude empty folders!
                        addresses.append(adr)
                    }
                }
            }
        }
        return addresses
    }

    func allKeysInFolder(folder: Folder) -> [String] {
        let fReq = NSFetchRequest<NSFetchRequestResult>(entityName: "PersistentMail")
        var predicates = [NSPredicate]()
        predicates.append(NSPredicate(format: "folder = %@", folder))
        predicates.append(NSPredicate(format: "keyID.length > 0"))
        let andPredicates = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        fReq.predicate = andPredicates
        fReq.propertiesToFetch = ["keyID"]
        fReq.resultType = NSFetchRequestResultType.dictionaryResultType
        fReq.returnsDistinctResults = true
        var keys: [String] = [String]()

        let result = (try? self.managedObjectContext.fetch(fReq))

        if let res = result as? Array<NSDictionary> {
            for nsdict in res {
                if let keyID = nsdict.value(forKey: "keyID") as? String {
                    keys.append(keyID)
                }
            }

        }
        var mykeys = Set<String>()
        if let set = folder.mails{
            if let mails = set as? Set<PersistentMail>{
                for mail in mails{
                    if let key = mail.keyID{
                        mykeys.insert(key)
                    }
                }
            }
        }
        return Array(mykeys)
    }


    func allMailsInFolder(key: String?, contact: EnzevalosContact?, folder: Folder?, isSecure: Bool) -> [PersistentMail] {
        let fReq = NSFetchRequest<NSFetchRequestResult>(entityName: "PersistentMail")
        var predicates = [NSPredicate]()
        if let k = key, k != "" {
            predicates.append(NSPredicate(format: "signedKey.keyID = %@", k))
        }
        if let c = contact {
            if c.getMailAddresses().count == 0 {
            } else {
                let adr: Mail_Address = c.getMailAddresses()[0] as! Mail_Address
                predicates.append(NSPredicate(format: "from == %@", adr))
            }
        }
        if let f = folder {
            predicates.append(NSPredicate(format: "folder == %@", f))
        }
        let andPredicates = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        fReq.predicate = andPredicates
        fReq.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        if let result = (try? self.managedObjectContext.fetch(fReq)) as? [PersistentMail] {
            if isSecure {
                let secureMails = result.filter({
                    return $0.isSecure
                })
                return secureMails
            } else {
                let inSecureMails = result.filter({
                    return !$0.isSecure
                })
                return inSecureMails

            }
        }
        return []
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
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType) // This is why we have trouble with concurrency: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CoreData/Concurrency.html
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

        callForFolders(done: { _ in return })

    }

    func terminate() {
        save(during: "Terminating")
    }

    func save(during:String) {
        do {
            try managedObjectContext.save()
        } catch {
            //fatalError("Failure to save context\(error)")
            //print("Error during saving while: \(during)")
        }
    }

    private func deleteNum(_ entityName: String, type: String, search: UInt64) {
        let fReq: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fReq.predicate = NSPredicate(format: "\(type) = %D ", search)
        if let result = (try? self.managedObjectContext.fetch(fReq)) as? [NSManagedObject] {
            for object in result {
                self.managedObjectContext.delete(object)
            }
            save(during: "delete num")
        }
    }

    func delete(mail: PersistentMail) {
        self.managedObjectContext.delete(mail as NSManagedObject)
        save(during: "delete ")
    }

    func deleteMail(with uid: UInt64) {
        self.deleteNum("PersistentMail", type: "uid", search: uid)
    }

    private func removeAll(entity: String) {
        let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: entity))
        do {
            try managedObjectContext.execute(DelAllReqVar)
        } catch {
            print(error)
        }
    }




    func reset() {
        removeAll(entity: "PersistentMail")
        removeAll(entity: "Folder")
        removeAll(entity: "SecretKey")
        removeAll(entity: "PersistentKey")
        removeAll(entity: "EnzevalosContact")
        removeAll(entity: "Mail_Address")
        save(during: "reset")
    }

    // Save, load, search

    func newSecretKey(keyID: String) -> SecretKey {
        let sk: SecretKey
        if let key = findSecretKey(keyID: keyID) {
            sk = key
        } else {
            sk = NSEntityDescription.insertNewObject(forEntityName: "SecretKey", into: managedObjectContext) as! SecretKey
            sk.keyID = keyID
            sk.obsolete = false
            sk.importedDate = Date () as NSDate
            UserManager.storeUserValue(keyID as AnyObject, attribute: Attribute.prefSecretKeyID)
            let adr = UserManager.loadUserValue(Attribute.userAddr) as! String
            let name = UserManager.loadUserValue(Attribute.accountname) as? String ?? adr
            _ = getContact(name: name, address: adr, key: keyID, prefer_enc: true)
        }
        save(during: "new sk")
        return sk
    }
    
    func newSecretKeys(keyIds:[String])-> [SecretKey]{
        var sks = [SecretKey]()
        for id in keyIds{
            sks.append(newSecretKey(keyID: id))
        }
        return sks
    }

    func createNewSecretKey(adr: String) -> SecretKey{
        let keys = findSecretKeys()
        if keys.count > 0 {
            return findSecretKeys().first!
        }
        let pgp = SwiftPGP()
        let key = pgp.generateKey(adr: adr)
        let sk = DataHandler.handler.newSecretKey(keyID: key)
        let pk = DataHandler.handler.newPublicKey(keyID: key, cryptoType: CryptoScheme.PGP, adr: adr, autocrypt: false, newGenerated: true)
        pk.sentOwnPublicKey = true
        return sk
    }

    func newPublicKey(keyID: String, cryptoType: CryptoScheme, adr: String, autocrypt: Bool, firstMail: PersistentMail? = nil, newGenerated: Bool = false) -> PersistentKey {
        var date = Date.init()
        if let mail = firstMail{
            if date.compare(mail.date).rawValue > 0{
                date = mail.date
            }
        }
        let adr = getMailAddress(adr, temporary: false) as! Mail_Address
        var pk: PersistentKey
        if let search = findKey(keyID: keyID) {
            if search.lastSeen < date{
                search.lastSeen = date
            }
            if autocrypt {
                if search.lastSeenAutocrypt < date{
                    search.lastSeenAutocrypt = date
                }
                search.sentOwnPublicKey = true
            }
            search.addToMailaddress(adr)
            pk = search
//            Logger.queue.async(flags: .barrier) {
                if Logger.logging {
                    var importChannel = "autocrypt"
                    if newGenerated {
                        importChannel = "generated"
                    } else if !autocrypt {
                        importChannel = "attachment"
                    }
                    Logger.log(discover: pk.keyID, mailAddress: adr, importChannel: importChannel, knownPrivateKey: DataHandler.handler.findSecretKeys().map{($0.keyID ?? "") == keyID}.reduce(false, {$0 || $1}), knownBefore: true)
                }
//            }
        } else {
            pk = NSEntityDescription.insertNewObject(forEntityName: "PersistentKey", into: managedObjectContext) as! PersistentKey
            pk.addToMailaddress(adr)
            pk.keyID = keyID
            pk.encryptionType = cryptoType
            pk.lastSeen = date
            pk.discoveryDate = date
            pk.firstMail = firstMail
            if autocrypt {
                pk.lastSeenAutocrypt = date 
                pk.sentOwnPublicKey = true
            }
            var found = false
            while !found {
                let pseudo = String.random()
                let response = find("PersistentKey", type: "pseudonym", search: pseudo) as? [PersistentKey]
                if (response ?? []).count == 0 || response![0].pseudonym == "" {
                    pk.pseudonym = pseudo
                    found = true
                }
            }
            save(during: "new pk")
//            Logger.queue.async(flags: .barrier) {
                if Logger.logging {
                    var importChannel = "autocrypt"
                    if newGenerated {
                        importChannel = "generated"
                    } else if !autocrypt {
                        importChannel = "attachment"
                    }
                    Logger.log(discover: pk.keyID, mailAddress: adr, importChannel: importChannel, knownPrivateKey: DataHandler.handler.findSecretKeys().map{($0.keyID ?? "") == keyID}.reduce(false, {$0 || $1}), knownBefore: false)
                }
//            }
        }
        if let prim = adr.primaryKey, let last = prim.lastSeen, let currentLast = pk.lastSeen{
            if last < currentLast {
                adr.primaryKeyID = pk.keyID
            }
        }
        else{
            adr.primaryKeyID = keyID
        }
        save(during: "new PK")
        return pk
    }
    
    func prefSecretKey()->SecretKey{
        if let prefId = UserManager.loadUserValue(Attribute.prefSecretKeyID){
            if let id = prefId as? String{
                if let key =  findSecretKey(keyID: id){
                    return key
                }
            }
        }
        var allSKs = findSecretKeys()
        allSKs = allSKs.sorted(by: {($0.importedDate)!<($1.importedDate)!})
        if allSKs.count > 0{
            UserManager.storeUserValue(allSKs[0].keyID as AnyObject, attribute: Attribute.prefSecretKeyID)
            return allSKs[0]
        }
        if let adr = UserManager.loadUserValue(Attribute.userAddr){
            if let adrString = adr as? String{
                return createNewSecretKey(adr: adrString)
            }
        }
        return createNewSecretKey(adr: "")
    }

    func findSecretKeys() -> [SecretKey] {
        if let result = findAll("SecretKey") {
            return result as! [SecretKey]
        }
        return [SecretKey]()
    }

    func findSecretKey(keyID: String) -> SecretKey? {
        if let result = find("SecretKey", type: "keyID", search: keyID) {
            for r in result {
                return r as? SecretKey
            }
        }
        return nil
    }

    func findKey(keyID: String) -> PersistentKey? {
        if let result = find("PersistentKey", type: "keyID", search: keyID) {
            for r in result {
                return r as? PersistentKey
            }
        }
        return nil
    }

    private func find(_ entityName: String, type: String, search: String) -> [AnyObject]? {
        let fReq: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fReq.predicate = NSPredicate(format: "\(type) CONTAINS %@ ", search) //FIXME: Was ist hier mit Injections? Vorsicht wo das verwendet wird! Nicht, dass hier UI Eingaben reinkommen können...
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
        let fReq: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
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
        let fReq: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let result: [AnyObject]?
        do {
            result = try self.managedObjectContext.fetch(fReq)
        } catch _ as NSError {
            result = nil
            return nil
        }
        return result
    }


    func findFolder(with path: String) -> Folder {
        if let search = find("Folder", type: "path", search: path) {
            if search.count > 0 {
                return search[0] as! Folder
            }
        }
        let folder = NSEntityDescription.insertNewObject(forEntityName: "Folder", into: managedObjectContext) as! Folder
        folder.path = path
        var found = false
        while !found {
            let pseudo = String.random()
            let response = find("Folder", type: "pseudonym", search: pseudo) as? [Folder]
            if (response ?? []).count == 0 || response![0].pseudonym == "" {
                folder.pseudonym = pseudo
                found = true
            }
        }
        return folder
    }

    func existsFolder(with path: String) -> Bool {
        if let search = find("Folder", type: "path", search: path), search.count > 0 {
            return true
        }
        return false
    }
    
    func getKeyRecord(addr: String, keyID: String?) -> KeyRecord{
        if let id = keyID{
            if let key = findKey(keyID: id){
                if let record = key.record{
                    return record
                }
                // Create KeyRecord
                let record = NSEntityDescription.insertNewObject(forEntityName: "KeyRecord", into: managedObjectContext) as! KeyRecord
                record.key = key
                if let contact = getContact(keyID: id){
                    record.contact = contact
                }
                else{
                    record.contact = getContactByAddress(addr)
                }
                save(during: "create keyRecord with key")
                return record
            }
        }
        
        if let address = findMailAddress(adr: addr){
            if let contact = address.contact{
                for record in contact.records{
                    if !record.hasKey{
                        for a in record.addresses{
                            if a.mailAddress == addr{
                                return record
                            }
                        }
                    }
                }
            }
        }
        // create KeyRecord
        let record = NSEntityDescription.insertNewObject(forEntityName: "KeyRecord", into: managedObjectContext) as! KeyRecord
        record.contact = getContactByAddress(addr)
        save(during: "create keyRecord without key")
        return record
    }

    // -------- Handle mail addresses ---------
    func getMailAddress(_ address: String, temporary: Bool) -> MailAddress {
        let adr = address.lowercased()
        let search = find("Mail_Address", type: "address", search: adr)
        if search == nil || search!.count == 0 {
            if temporary {
                return CNMailAddressExtension(addr: adr as NSString)
            } else {
                let mail_address = NSEntityDescription.insertNewObject(forEntityName: "Mail_Address", into: managedObjectContext) as! Mail_Address
                mail_address.address = adr
                var found = false
                while !found {
                    let pseudo = String.random()
                    let response = find("Mail_Address", type: "pseudonym", search: pseudo) as? [Mail_Address]
                    if (response ?? []).count == 0 || response![0].pseudonym == "" {
                        mail_address.pseudonym = pseudo
                        found = true
                    }
                }
                return mail_address
            }
        } else {
            return search![0] as! Mail_Address
        }
    }

    func findMailAddress(adr: String) -> Mail_Address? {
        if let search = find("Mail_Address", type: "address", search: adr) {
            if search.count > 0 {
                return search[0] as? Mail_Address
            }
        }
        return nil
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
        let lowerAdr = address.lowercased()
        if let mailAdr = findMailAddress(adr: address) {
            if let contact = mailAdr.contact {
                return contact
            }
        }
        if let contacts = findAll("EnzevalosContact") {
            for c in contacts {
                if case let contact as EnzevalosContact = c {
                    for adr in contact.addresses{
                        if case let mailAdr as Mail_Address = adr {
                            if mailAdr.address == address {
                                return contact
                            }
                        }
                    }
                    if let cnContact = contact.cnContact {
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
        adr.contact = contact
        let cncontacts = AddressHandler.findContact(contact)
        if cncontacts.count > 0{
            contact.cnidentifier = cncontacts.first?.identifier
        }
        return contact
    }
    
    func getContact(keyID: String)-> EnzevalosContact?{
        if let key = findKey(keyID: keyID){
            if let adrs = key.mailaddress{
                for item in adrs{
                    let adr = item as! Mail_Address
                    if adr.contact != nil{
                        return adr.contact
                    }
                }
            }
        }
        return nil
    }

    func getContact(name: String, address: String, key: String, prefer_enc: Bool) -> EnzevalosContact {
        let contact = getContactByAddress(address)
        contact.displayname = name
        if let mykey = findKey(keyID: key){
            contact.getAddress(address)?.addToKeys(mykey)
        }
        return contact
    }

    func getContacts(receivers: [MCOAddress]) -> [EnzevalosContact] {
        var contacts = [EnzevalosContact]()
        var contact: EnzevalosContact
        for r in receivers {
            contact = getContactByMCOAddress(address: r)
            contacts.append(contact)
        }
        return contacts
    }

    func getContactByMCOAddress(address: MCOAddress) -> EnzevalosContact {
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
        adr = getMailAddressByMCOAddress(sender, temporary: false) as! Mail_Address
        if adr.contact == nil {
            adr.contact = getContactByMCOAddress(address: sender)
        }
        if let contact = adr.contact {
            if !(contact.addresses.contains(adr)) {
                    contact.addToAddresses(adr)
            }
        }
        fromMail.from = adr
    }

    private func handleToAddresses(_ receivers: [MCOAddress], mail: PersistentMail) {
        mail.addToTo(NSSet(array: getMailAddressesByMCOAddresses(receivers)))
    }

    private func handleCCAddresses(_ cc: [MCOAddress], mail: PersistentMail) {
        mail.addToCc(NSSet(array: getMailAddressesByMCOAddresses(cc)))
    }
    
    private func findMail(msgID: String) -> PersistentMail?{
        if let result = find("PersistentMail", type: "messageID", search: msgID) as?[PersistentMail]{
            if result.count > 0{
                return result[0]
            }
        }
        return nil
    }

    // TODO: handle BCC

    // -------- End handle to, cc, from addresses --------

    func createMail(_ uid: UInt64, sender: MCOAddress?, receivers: [MCOAddress], cc: [MCOAddress], time: Date, received: Bool, subject: String, body: String?, flags: MCOMessageFlag, record: KeyRecord?, autocrypt: AutocryptContact?, decryptedData: CryptoObject?, folderPath: String, secretKey: String?, references: [String] = [], mailagent: String? = nil, messageID: String? = nil) -> PersistentMail? {
        let myfolder = findFolder(with: folderPath) as Folder
        let finding = findNum("PersistentMail", type: "uid", search: uid)
        let mail: PersistentMail
        var mails: [PersistentMail] = []

        if let tmpMails = finding as? [PersistentMail] {
            mails = tmpMails
        }

        if finding == nil || finding!.count == 0 || mails.filter( {$0.folder.path == folderPath && $0.uidvalidity == myfolder.uidvalidity}).count == 0 {
            // create new mail object
            mail = NSEntityDescription.insertNewObject(forEntityName: "PersistentMail", into: managedObjectContext) as! PersistentMail
            
            mail.date = time
            mail.subject = subject
            mail.body = body
            mail.secretKey  = secretKey

            mail.folder = myfolder
            mail.uidvalidity = myfolder.uidvalidity
            mail.uid = uid
            mail.messageID = messageID
            mail.xMailer = mailagent
            
            mail.flag = flags
            // Default values
            mail.isSigned = false
            mail.isEncrypted = false
            mail.trouble = false
            mail.unableToDecrypt = false
            mail.received = received
           
            var notStored = ""
            for reference in references{
                if let ref = findMail(msgID: reference){
                   // mail.addToReferenceMails(ref)
                }
                else{
                    notStored = notStored + " ; "+(reference)
                }
            }
            if notStored != ""{
                //mail.notLoadedMessages = notStored
            }

            if sender != nil {
                handleFromAddress(sender!, fromMail: mail, autocrypt: autocrypt)
            }
            handleToAddresses(receivers, mail: mail)
            handleCCAddresses(cc, mail: mail)


            if let decData = decryptedData {
                let encState: EncryptionState = decData.encryptionState
                let signState: SignatureState = decData.signatureState

                switch encState {
                case EncryptionState.NoEncryption:
                    mail.isEncrypted = false
                    mail.trouble = false
                    mail.unableToDecrypt = false
                case EncryptionState.UnableToDecrypt:
                    mail.unableToDecrypt = true
                    mail.isEncrypted = true
                    mail.trouble = false
                case EncryptionState.ValidEncryptedWithOldKey, EncryptionState.ValidedEncryptedWithCurrentKey:
                    mail.isEncrypted = true
                    mail.trouble = false
                    mail.unableToDecrypt = false
                    mail.decryptedBody = body
                }

                switch signState {
                case SignatureState.NoSignature:
                    mail.isSigned = false
                case SignatureState.NoPublicKey:
                    mail.isSigned = true
                    mail.isCorrectlySigned = false
                case SignatureState.InvalidSignature:
                    mail.isSigned = true
                    mail.isCorrectlySigned = true
                    mail.trouble = true
                case SignatureState.ValidSignature:
                    mail.isCorrectlySigned = true
                    mail.isSigned = true
                    if let signedKey = findKey(keyID: decData.signKey!){
                        mail.signedKey = signedKey
                        mail.keyID = signedKey.keyID
                    }
                    else{
                        mail.signedKey = newPublicKey(keyID: decData.signKey!, cryptoType: decData.encType, adr: decData.signedAdrs.first!, autocrypt: false, firstMail: mail, newGenerated: false)
                    }
                   
                }
            }
                else {
                    // Maybe PGPInline?
                    // TODO: Refactoring!
                    //mail.decryptIfPossible()
            }
        }
        else {
            return nil
        }
        myfolder.addToMails(mail)
        if mail.uid > myfolder.maxID {
            myfolder.maxID = mail.uid
        }
        var record = getKeyRecord(addr: mail.from.mailAddress, keyID: nil)
        if let signedID = mail.signedKey?.keyID{
            record = getKeyRecord(addr: mail.from.mailAddress, keyID: signedID)
        }
        record.addToPersistentMails(mail)
        mail.folder.addToKeyRecords(record)
        save(during: "new mail")
        return mail
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
    

    func getAddresses() -> [MailAddress] {
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

    func getContacts() -> [EnzevalosContact] {
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




    func hasKey(adr: String) -> Bool {
        if let madr = findMailAddress(adr: adr) {
            return madr.hasKey
        }
        return false
    }

    func folderRecords(folderPath: String) -> [KeyRecord] {
        let folder = findFolder(with: folderPath) as Folder
        return folder.records
    }
}
