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
    
    
    let key: KeyWrapper?
    
    public var addresses: [MailAddress] = [MailAddress]()
    
    public var name: String{
        get{
            return ezContact.name
        }
    }
    public var isSecure: Bool
    
    public var isVerified: Bool
    
    
    public var mails: [Mail] = [Mail]()
    
    
    public var ezContact: EnzevalosContact
       
    
    public var cnContact: CNContact?{
        get{
            return ezContact.cnContact
        }
    }
    
    public var color: UIColor{
        get{
            return ezContact.getColor()
        }
    }
    
    public var image: UIImage{
        get{
            return ezContact.getImageOrDefault()
        }
    }
    
    
    public init(contact: EnzevalosContact, key: KeyWrapper?){
        self.key = key
        self.ezContact = contact

        if (key != nil) {
            self.isSecure = true
            self.isVerified = (key?.verified)!
        }
        else{
            self.isSecure = false
            self.isVerified = false
        }
        self.ezContact.records.append(self)

    }
    
    public init(mail: Mail){
        //TODO: KEY?????
        self.key = nil
        self.ezContact = mail.from.contact
        self.isSecure = mail.isEncrypted
        self.isVerified = false //TODO FIX
        self.ezContact.records.append(self)
        self.addNewMail(mail)
    }
    
    
    
    
    public func showInfos(){
        print("-----------------")
        print("Name: \(ezContact.displayname) | State: \(isSecure) | #Mails: \(mails.count)")
        print("First mail: \(mails.first?.uid) | Adr: \(mails.first?.from.address) | date: \(mails.first?.date.description) ")
        print("subj: \(mails.first?.subject?.capitalizedString)")
    
    }

    public func addNewAddress(adr: MailAddress) -> Bool {
        for a in addresses {
            if a.mailAddress == adr.mailAddress{
                return false
            }
        }
        addresses.append(adr)
        return true
    }
    
    public func addNewMail(mail: Mail)->Bool{
        if mail.isEncrypted == self.isSecure{
            if ezContact.getAddress(mail.from.address) != nil{
                for m in mails{
                    if m.uid == mail.uid{
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
        }
        return false
    }
    
    public func getImageOrDefault() -> UIImage {
        return ezContact.getImageOrDefault()
    }
    
    public func getColor() -> UIColor {
        return ezContact.getColor()
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
