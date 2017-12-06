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

    func checkRecords(records: [KeyRecord]) {
        for record in records {
            if record.addresses.count == 0 {
                print("Record has no addresses: \(record)")
            }
            if record.mails.count < record.mailsInFolder(folder: record.folder).count {
                print("Wrong matching of mails: \(record)")
            }
            for mail in record.mails {
                checkMail(mail: mail)
            }
            for mail in record.mailsInFolder(folder: record.folder) {
                checkMail(mail: mail)
            }
        }
    }

    func checkMail(mail: PersistentMail) {
        if mail.to.count == 0 && mail.cc == nil {
            print("Mail has no receiver: \(mail)")
        }
    }

    func checkFolder(folderName: String) {
        let folder = findFolder(with: folderName)
        if let mails = folder.mails {
            for m in mails {
                let mail = m as! PersistentMail
                checkMail(mail: mail)
            }
        }
        let records = folder.records
        checkRecords(records: records)
        checkRecords(records: folder.liveRecords)
    }



    func callForFolders(done: @escaping ((_ error: Bool) -> ())) { // Maybe call back? Look for new Folder?
        AppDelegate.getAppDelegate().mailHandler.allFolders { (err, array) -> Void in
            guard err == nil else {
                print("Error while fetching all folders: \(String(describing: err))")
                done(true)
                return
            }

            if let newFolders = array {
                for new in newFolders {
                    if case let folder as MCOIMAPFolder = new {
                        let f = self.findFolder(with: folder.path) //FIXME: this should take the full path instead of the name
                        f.delimiter = String(Character(UnicodeScalar(UInt8(folder.delimiter))))
                        f.flags = folder.flags
                    }
                }
            }
            done(false)
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
        predicates.append(NSPredicate(format: "keyID != nil"))
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
        return keys
    }


    func allMailsInFolder(key: String?, contact: EnzevalosContact?, folder: Folder?, isSecure: Bool) -> [PersistentMail] {
        let fReq = NSFetchRequest<NSFetchRequestResult>(entityName: "PersistentMail")
        var predicates = [NSPredicate]()
        if let k = key, k != "" {
            predicates.append(NSPredicate(format: "keyID = %@", k))
        }
        if let c = contact {
            if c.getMailAddresses().count == 0 {
                print("Contact with no Mail Adress: \(String(describing: c.displayname))")
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

        callForFolders(done: { _ in return })

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

    private func delete(_ entityName: String, type: String, search: String) {
        let fReq: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fReq.predicate = NSPredicate(format: "\(type) LIKE [cd] ", search) //FIXME: Was ist hier mit Injections? Vorsicht wo das verwendet wird! Nicht, dass hier UI Eingaben reinkommen können... https://stackoverflow.com/questions/3076894/how-to-prevent-sql-injection-in-core-data#3078076
        if let result = (try? self.managedObjectContext.fetch(fReq)) as? [NSManagedObject] {
            for object in result {
                self.managedObjectContext.delete(object)
            }
            save()
        }
    }

    private func deleteNum(_ entityName: String, type: String, search: UInt64) {
        let fReq: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fReq.predicate = NSPredicate(format: "\(type) = %D ", search)
        if let result = (try? self.managedObjectContext.fetch(fReq)) as? [NSManagedObject] {
            for object in result {
                self.managedObjectContext.delete(object)
            }
            save()
        }
    }

    func delete(mail: PersistentMail) {
        self.managedObjectContext.delete(mail as NSManagedObject)
        save()
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
        removeAll(entity: "Folder")
        removeAll(entity: "SecretKey")
        removeAll(entity: "PersistentKey")
        removeAll(entity: "EnzevalosContact")
        removeAll(entity: "Mail_Address")
        removeAll(entity: "PersistentMail")

        removeAll(entity: "PseudonymKey")
        removeAll(entity: "PseudonymMailAddress")
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
        }
        save()
        return sk
    }

    func createNewSecretKey(adr: String) {
        let keys = findSecretKeys()
        if keys.count > 0 {
            return
        }
        let pgp = SwiftPGP()
        let key = pgp.generateKey(adr: adr)
        let useraddr = (UserManager.loadUserValue(Attribute.userAddr) as! String)
        _ = DataHandler.handler.newSecretKey(keyID: key)
        _ = DataHandler.handler.newPublicKey(keyID: key, cryptoType: CryptoScheme.PGP, adr: useraddr, autocrypt: false)
    }

    func newPublicKey(keyID: String, cryptoType: CryptoScheme, adr: String, autocrypt: Bool, firstMail: PersistentMail? = nil) -> PersistentKey {
        let date = Date.init() as NSDate
        let adr = getMailAddress(adr, temporary: false) as! Mail_Address
        var pk: PersistentKey
        if let search = findKey(keyID: keyID) {
            search.lastSeen = date
            if autocrypt {
                search.lastSeenAutocrypt = date
            }
            search.addToMailaddress(adr)
            pk = search
        } else {
            pk = NSEntityDescription.insertNewObject(forEntityName: "PersistentKey", into: managedObjectContext) as! PersistentKey
            pk.addToMailaddress(adr)
            pk.keyID = keyID
            pk.encryptionType = Int16(cryptoType.hashValue)
            pk.lastSeen = date
            pk.discoveryDate = date
            pk.firstMail = firstMail
            if autocrypt {
                pk.lastSeenAutocrypt = date
            }
        }
        save()
        return pk
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
        return folder
    }

    func existsFolder(with path: String) -> Bool {
        if let search = find("Folder", type: "path", search: path), search.count > 0 {
            return true
        }
        return false
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
                    if let adrs = contact.addresses {
                        for adr in adrs {
                            if case let mailAdr as Mail_Address = adr {
                                if mailAdr.address == address {
                                    return contact
                                }
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
        return contact
    }

    func getContact(name: String, address: String, key: String, prefer_enc: Bool) -> EnzevalosContact {
        let contact = getContactByAddress(address)
        contact.displayname = name
        contact.getAddress(address)?.key?.adding(key)
        //TODO IOptimize: look for Mail_Address and than for contact!
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
            if contact.addresses == nil {
                contact.addToAddresses(adr)
            }
                else if !(contact.addresses?.contains(adr))! {
                    contact.addToAddresses(adr)
            }
            if contact.addresses == nil || contact.addresses?.count == 0 {
                print("ERROR Contact has no addresses!")
            }
        }
            else {
                print("ERROR! No ENzContact!")
        }

        //let contact = getContactByMCOAddress(sender)
        // adr = contact.getAddressByMCOAddress(sender)!

        /* TODO: Handle AUtocrypt again!
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
             */
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

    func createMail(_ uid: UInt64, sender: MCOAddress?, receivers: [MCOAddress], cc: [MCOAddress], time: Date, received: Bool, subject: String, body: String?, flags: MCOMessageFlag, record: KeyRecord?, autocrypt: AutocryptContact?, decryptedData: CryptoObject?, folderPath: String) -> PersistentMail? {

        let finding = findNum("PersistentMail", type: "uid", search: uid)
        let mail: PersistentMail
        var mails: [PersistentMail] = []

        if let tmpMails = finding as? [PersistentMail] {
            mails = tmpMails
        }

        if finding == nil || finding!.count == 0 || mails.filter( { $0.folder.path == folderPath }).count == 0 {
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

            if sender != nil {
                handleFromAddress(sender!, fromMail: mail, autocrypt: autocrypt)
            }
            handleToAddresses(receivers, mail: mail)
            handleCCAddresses(cc, mail: mail)

            mail.unableToDecrypt = false

            if let decData = decryptedData {
                let encState: EncryptionState = decData.encryptionState
                let signState: SignatureState = decData.signatureState
                mail.keyID = decData.signKey

                switch encState {
                case EncryptionState.NoEncryption:
                    mail.isEncrypted = false
                    mail.trouble = false
                    mail.unableToDecrypt = false
                case EncryptionState.UnableToDecrypt:
                    mail.unableToDecrypt = true
                    mail.isEncrypted = true
                    mail.trouble = true
                case EncryptionState.ValidEncryptedWithOldKey, EncryptionState.ValidedEncryptedWithCurrentKey:
                    mail.isEncrypted = true
                    mail.trouble = false
                    mail.unableToDecrypt = false
                    mail.decryptedBody = body
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
        let myfolder = findFolder(with: folderPath) as Folder
        myfolder.addToMails(mail)
        if mail.uid > myfolder.maxID {
            myfolder.maxID = mail.uid
        }
        save()
        return mail
    }

    private func createPseudonymMailAddress(mailAddress: String) -> PseudonymMailAddress {
        let pseudonymMailAddress = NSEntityDescription.insertNewObject(forEntityName: "PseudonymMailAddress", into: managedObjectContext) as! PseudonymMailAddress
        var found = false
        while !found {
            let pseudo = String.random()
            let response = find("PseudonymMailAddress", type: "pseudonym", search: pseudo) as? [PseudonymMailAddress]
            if (response ?? []).count == 0 || response![0].pseudonym == "" {
                pseudonymMailAddress.pseudonym = pseudo
                found = true
            }
        }
        pseudonymMailAddress.address = mailAddress.lowercased()
        save()
        return pseudonymMailAddress
    }
    
    func getPseudonymMailAddress(mailAddress: String) -> PseudonymMailAddress {
        let result = find("PseudonymMailAddress", type: "address", search: mailAddress.lowercased())
        if let list = result as? [PseudonymMailAddress], list.count > 0 {
            return list[0]
        }
        return createPseudonymMailAddress(mailAddress: mailAddress)
    }
    
    private func createPseudonymKey(keyID: String) -> PseudonymKey {
        let pseudonymKey = NSEntityDescription.insertNewObject(forEntityName: "PseudonymKey", into: managedObjectContext) as! PseudonymKey
        var found = false
        while !found {
            let pseudo = String.random()
            let response = find("PseudonymKey", type: "pseudonym", search: pseudo) as? [PseudonymKey]
            if (response ?? []).count == 0 || response![0].pseudonym == "" {
                pseudonymKey.pseudonym = pseudo
                found = true
            }
        }
        pseudonymKey.keyID = keyID.lowercased()
        save()
        return pseudonymKey
    }
    
    func getPseudonymKey(keyID: String) -> PseudonymKey {
        let result = find("PseudonymKey", type: "keyID", search: keyID.lowercased())
        if let list = result as? [PseudonymKey], list.count > 0 {
            return list[0]
        }
        return createPseudonymKey(keyID: keyID)
    }
    
    private func createPseudonymSubject(subject: String) -> PseudonymSubject {
        let pseudonymSubject = NSEntityDescription.insertNewObject(forEntityName: "PseudonymSubject", into: managedObjectContext) as! PseudonymSubject
        var found = false
        while !found {
            let pseudo = String.random()
            let response = find("PseudonymSubject", type: "pseudonym", search: pseudo) as? [PseudonymSubject]
            if (response ?? []).count == 0 || response![0].pseudonym == "" {
                pseudonymSubject.pseudonym = pseudo
                found = true
            }
        }
        pseudonymSubject.subject = subject
        save()
        return pseudonymSubject
    }
    
    func getPseudonymSubject(subject: String) -> PseudonymSubject {
        let result = find("PseudonymSubject", type: "subject", search: subject)
        if let list = result as? [PseudonymSubject], list.count > 0 {
            return list[0]
        }
        return createPseudonymSubject(subject: subject)
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
