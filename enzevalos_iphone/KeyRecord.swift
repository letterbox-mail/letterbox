//
//  KeyRecord.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 06/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Contacts
import UIKit

open class KeyRecord: Record {

    /*
     A record contains a signing key (or none because of insecure communication), a contact (inlucding mail-addresses) and mails.
     For each key we have a different record for mailboxes. Mails and contact are affliate with the key.
     Each mail is signed with the key or unsigned. The contact contains the ''from-'' mail-addresses of signed mails (or unsigned).
     */

    let key: String?
    
    let cryptoscheme = CryptoScheme.PGP
    
    let folder: Folder
    
    open var isSecure: Bool = false
    
    
    open var ezContact: EnzevalosContact

    
    var pgpKey: PGPKey?{
        get{
            if let k = key{
                let pgp = SwiftPGP()
                 return pgp.loadKey(id: k)
            }
            return nil
        }
    }
    
    var storedKey: PersistentKey?{
        get{
            if let k = keyId{
                return DataHandler.handler.findKey(keyID: k)
            }
            return nil
        }
    
    }
    
    
    
    public var isVerified: Bool{
        get{
            if let k = key{
                if let pk = DataHandler.handler.findKey(keyID: k){
                    return pk.isVerified()
                }
            }
            return false
            
        }
    }
    
    func verify(){
        if let k = key{
            if let pk = DataHandler.handler.findKey(keyID: k){
                pk.verify()
            }
        }
    }
    
    var fingerprint: String?{
        get{
            if let k = pgpKey{
                return k.keyID.longKeyString
            }
            return nil
        }
    }
    
    var keyId: String?{
        get{
            if let k = pgpKey{
                return k.keyID.shortKeyString
            }
            return nil
        }
    
    }
    
    open var mails: [PersistentMail] {
        get{
            return mailsInFolder(folder: folder)
        }
    }

    open var addresses: [MailAddress] {
        if let adr = ezContact.addresses{
            return Array(adr) as! [MailAddress]
        }
        return []
    }
    
    var addressNames:[String]{
        get{
            let adrs = addresses
            var names = [String]()
            for adr in adrs{
                names.append(adr.mailAddress)
            }
            return names
        }
    }

    open var name: String {
        return ezContact.name
    }
    open var hasKey: Bool {
        // Public encryption key. May missing for secure mails since mail is only signed and encrypted
        return key != nil
    }
    

    open var cnContact: CNContact? {
        return ezContact.cnContact
    }

    open var image: UIImage {
        return ezContact.getImageOrDefault()
    }
    open var color: UIColor {
        return ezContact.getColor()
    }


    public init(keyID: String?, contact: EnzevalosContact, folder: Folder) {
        key = keyID
        ezContact = contact
        self.folder = folder
        if key != nil{
            isSecure = true
        }
    }
    
    public init(contact: EnzevalosContact, folder: Folder){
        key = nil
        ezContact = contact
        self.folder = folder
        isSecure = false
    }
    
    public init (keyID: String, folder: Folder){
        key = keyID
        self.folder = folder
        isSecure = true
        let mails = DataHandler.handler.allMailsInFolder(key: keyID, contact: nil, folder: folder, isSecure: isSecure)
        if mails.count > 0{
            if let c = mails[0].from.contact{
                ezContact = c
            }
            else{
                ezContact = DataHandler.handler.getContact(name: "", address: "", key: "", prefer_enc: false)
            }
        }
        else{
            ezContact = DataHandler.handler.getContact(name: "", address: "", key: "", prefer_enc: false)
        }
    }
    

    
    func mailsInFolder(folder: Folder?) -> [PersistentMail]{
        return DataHandler.handler.allMailsInFolder(key: key, contact: ezContact, folder: folder, isSecure: isSecure)
    }

   



    open func showInfos() {
        print("-----------------")
        print("Name: \(String(describing: ezContact.displayname)) | State: \(hasKey) | #Mails: \(mails.count)")
        print("First mail: \(String(describing: mails.first?.uid)) | Adr: \(String(describing: mails.first?.from.mailAddress)) | date: \(String(describing: mails.first?.date.description)) ")
        print("subj: \(String(describing: mails.first?.subject?.capitalized))")
    }

    open func getImageOrDefault() -> UIImage {
        return ezContact.getImageOrDefault()
    }
    
    func matchMail(mail: PersistentMail) -> Bool{
        if self.isSecure == mail.isSecure && self.folder == mail.folder{
            if isSecure && self.key == mail.keyID {
                return true
            }
            else if !isSecure {
                if self.ezContact == mail.from.contact && mail.from.contact != nil{
                    return true
                }
                for adr in addresses{
                    if adr.mailAddress == mail.from.mailAddress {
                        return true
                    }
                    
                }
            }
        }
        return false
    }

}



private func isEmpty(_ contact: KeyRecord) -> Bool {
    return contact.mails.count == 0
}


public func == (lhs: KeyRecord, rhs: KeyRecord) -> Bool {
    if isEmpty(lhs) {
        return false
    }
    if isEmpty(rhs) {
        return false
    }
    return lhs.mails.first!.date == rhs.mails.first!.date && lhs.hasKey == rhs.hasKey && lhs.key == rhs.key
}

public func < (lhs: KeyRecord, rhs: KeyRecord) -> Bool {
    if isEmpty(lhs) {
        return true
    }
    if isEmpty(rhs) {
        return false
    }
    return lhs.mails.first!.date > rhs.mails.first!.date
}
