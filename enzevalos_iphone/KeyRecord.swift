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

public class KeyRecord: Record{
    /*
     A record contains a signing key (or none because of insecure communication), a contact (inlucding mail-addresses) and mails.
     For each key we have a different record for mailboxes. Mails and contact are affliate with the key.
     Each mail is signed with the key or unsigned. The contact contains the ''from-'' mail-addresses of signed mails (or unsigned).
     */
    
    let key: String?
    
    public var addresses: [MailAddress] = [MailAddress]()
    
    public var name: String{
        get{
            return ezContact.name
        }
    }
    public var hasKey: Bool {
        return key != nil
    }
    
    public var isVerified: Bool {
        if let key = self.key{
            if let keywrapper = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)?.getKey(key){
                return keywrapper.verified
            }
        
        }
        return false
    }
    
    
    public var mails: [Mail] = [Mail]()
    
    
    public var ezContact: EnzevalosContact

    public var cnContact: CNContact? {
        get{
            return ezContact.cnContact
        }
    }
    
    public init(contact: EnzevalosContact, key: String?){
        self.ezContact = contact
        self.key = key
        self.mails = [Mail] ()
    }
    
    public var image: UIImage{
        get{
            return ezContact.getImageOrDefault()
        }
    }
    public var color: UIColor {
        get{
            return ezContact.getColor()
        }
    }
  
    
    public init(mail: Mail){
        self.key = mail.from.keyID
        self.ezContact = mail.from.contact
        self.ezContact.records.append(self)
        self.addNewMail(mail)
        if mail.isEncrypted{
            print("New encrypted mail")
            if let k = mail.from.keyID{
                print("Keys: \(k) and contact: \(self.key)")
            }
        }
       
    }
    
    
    
    
    public func showInfos(){
        print("-----------------")
        print("Name: \(ezContact.displayname) | State: \(hasKey) | #Mails: \(mails.count)")
        print("First mail: \(mails.first?.uid) | Adr: \(mails.first?.from.address) | date: \(mails.first?.date.description) ")
        print("subj: \(mails.first?.subject?.capitalizedString)")
    
    }

    public func addNewAddress(adr: MailAddress) -> Bool {
        for a in addresses {
            if a.mailAddress == adr.mailAddress {
                return false
            }
        }
        addresses.append(adr)
        return true
    }
    
    public func addNewMail(mail: Mail)->Bool {
        if mail.isEncrypted && self.hasKey{
            print("Same key?: \(mail.from.keyID) vs \(self.key)")
            if mail.from.keyID == self.key{
                mails.append(mail)
                mails.sortInPlace()
                addNewAddress(mail.from)
                return true
            }
            return false
            
        }
        else if mail.isEncrypted && !self.hasKey || !mail.isEncrypted && self.hasKey{
            return false
        }//TODO: FIX ME!
        if ezContact.getAddress(mail.from.address) != nil {
            for m in mails {
                if m.uid == mail.uid {
                    return true
                }
                else if m.uid < mail.uid {
                    break
                }
            }
            mails.append(mail)
            mails.sortInPlace()
            addNewAddress(mail.from)
            return true
        }
        return false
    }
    
    public func getImageOrDefault() -> UIImage {
        return ezContact.getImageOrDefault()
    }
    
    
}



private func isEmpty(contact: KeyRecord)-> Bool{
    if(contact.mails.count == 0){
        return true
    }
    return false
    
}


public func ==(lhs: KeyRecord, rhs: KeyRecord) -> Bool {
    if isEmpty(lhs){
        return false
    }
    if isEmpty(rhs){
        return false
    }
    
    return lhs.mails.first!.date == rhs.mails.first!.date
}

public func <(lhs: KeyRecord, rhs: KeyRecord) -> Bool {
    if isEmpty(lhs){
        return true
    }
    if isEmpty(rhs){
        return false
    }
    return lhs.mails.first!.date > rhs.mails.first!.date
}
