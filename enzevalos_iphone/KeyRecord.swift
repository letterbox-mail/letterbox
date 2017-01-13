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
    
    
    private let contact: EnzevalosContact
    let key: KeyWrapper?
    
    public var name: String{
        get{
            return contact.getName()
        }
    }
    public var isSecure: Bool
    
    public var isVerified: Bool
    
    var mails: [Mail]
    
    
    
    
    public init(contact: EnzevalosContact, key: KeyWrapper?){
        self.contact = contact
        self.key = key
        self.mails = [Mail] ()
        if (key != nil) {
            self.isSecure = true
            self.isVerified = (key?.verified)!
        }
        else{
            self.isSecure = false
            self.isVerified = false
        }
    }
    
    public init(mail: Mail){
        self.contact = mail.getFrom().contact
        self.mails = [Mail] ()
        //TODO: KEY?????
        key = nil
        self.isSecure = mail.isEncrypted
        self.isVerified = false //TODO FIX
        
        self.updateMails(mail)
    }
    
    
    
    
    public func showInfos(){
        print("-----------------")
        print("Name: \(contact.displayname) | State: \(isSecure) | #Mails: \(mails.count)")
        print("First mail: \(mails.first?.uid) | Adr: \(mails.first?.getFrom().address) | date: \(mails.first?.date.description) ")
        print("subj: \(mails.first?.subject?.capitalizedString)")
    
    }
    
    public func getContact()->EnzevalosContact{
        return contact
    }
    
    public func getCNContact() -> CNContact? {
        return contact.cnContact
    }
    
    public func getFromMails()->[Mail]{
        return mails
    }
    public func updateMails(mail: Mail)->Bool{
        if mail.isEncrypted == self.isSecure{
            if getContact().getAddress(mail.getFrom().address) != nil{
                for m in mails{
                  if m.uid == mail.uid{
                       return true
                  }
                  else if m.uid < mail.uid { //TODO CHECK!!!
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
        return contact.getImageOrDefault()
    }
    
    public func getColor() -> UIColor {
        return contact.getColor()
    }
}



private func isEmpty(contact: KeyRecord)-> Bool{
    if(contact.getFromMails().count == 0){
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
    
    return lhs.getFromMails().first!.date == rhs.getFromMails().first!.date
}

public func <(lhs: KeyRecord, rhs: KeyRecord) -> Bool {
    if isEmpty(lhs){
        return true
    }
    if isEmpty(rhs){
        return false
    }
    return lhs.getFromMails().first!.date > rhs.getFromMails().first!.date
}
