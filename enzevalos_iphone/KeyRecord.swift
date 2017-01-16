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
    
    public var name: String{
        get{
            return ezContact.name
        }
    }
    public var isSecure: Bool
    
    public var isVerified: Bool
    
    
    private var fromMails: [Mail]
    public var mails: [Mail]{
        get{
            return self.fromMails
        }
        set{
            self.fromMails = newValue
        }
    }
    
    
    private var enzevalosContact: EnzevalosContact
    
    public var ezContact: EnzevalosContact{
        get{
            return self.enzevalosContact
        }
    }
    
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
        self.enzevalosContact = contact
        if (key != nil) {
            self.isSecure = true
            self.isVerified = (key?.verified)!
        }
        else{
            self.isSecure = false
            self.isVerified = false
        }
        self.fromMails = [Mail] ()
    }
    
    public init(mail: Mail){
        //TODO: KEY?????
        self.key = nil
        self.enzevalosContact = mail.from.contact
        self.isSecure = mail.isEncrypted
        self.isVerified = false //TODO FIX
        
        self.fromMails = [Mail] ()
        self.updateMails(mail)
    }
    
    
    
    
    public func showInfos(){
        print("-----------------")
        print("Name: \(ezContact.displayname) | State: \(isSecure) | #Mails: \(mails.count)")
        print("First mail: \(mails.first?.uid) | Adr: \(mails.first?.from.address) | date: \(mails.first?.date.description) ")
        print("subj: \(mails.first?.subject?.capitalizedString)")
    
    }

    
    
    public func updateMails(mail: Mail)->Bool{
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
