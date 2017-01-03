//
//  EnzevalosContact+CoreDataClass.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 27/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData
import UIKit
import Contacts


//TODO: add CNContact

@objc(EnzevalosContact)
public class EnzevalosContact: NSManagedObject {
    
    func update(name: String, key: String, prefer_enc: Bool){
        setDisplayName(name)
        self.key = key
        self.prefer_encryption = prefer_enc
    }
    
    func setAddress(address: String){
        self.mail_address = address
    }
    
    func addFromMail(fromMail: Mail){
        self.addToFrom(fromMail)
    }
    
    func addToMail(mail: Mail){
        self.addToTo(mail)
    }
    
    func addCCMail(mail: Mail){
       // self.addToCc(mail)
    }
    
    func setDisplayName(name: String){
        self.displayname = name
    }
    
    
    // TODO: Sort Onetime!
    func getFromMails()-> [Mail]{
        var fromMails: [Mail]
        fromMails = self.from!.allObjects as! [Mail]
        fromMails.sortInPlace({$0 < $1})
        return fromMails
    }
    
    //TODO: FIX ME
    func getContact()->CNContact{
        // TODO: Check if contact exists in address book
        //        let contactFromBook = AddressHandler.contactByEmail((mail.sender?.mailbox)!)
        //        if let con = contactFromBook {
        //            contacts.append(EnzevalosContact(contact: con, mails: [mail]))
        //            return
        //        }
        
        // New contact has to be added
        let con = CNMutableContact()
        let name = self.displayname
        if let n = name {
            let nameArray = n.characters.split(" ").map(String.init)
            switch nameArray.count {
            case 1:
                con.givenName = nameArray.first!
            case 2..<20: // who has more than two names?!
                con.givenName = nameArray.first!
                con.familyName = nameArray.last!
            default:
                con.givenName = "NO"
                con.familyName = "NAME"
            }
        }
        con.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: self.mail_address!)]
        //contacts.append(self.mail_address!) TODO: ???????
        return con
    }
    
    func toString()->String{
        if(mail_address != nil){
            return self.mail_address!
        }
        return "NO NAME"
    }
    
    func getMailAddresses()->[String]{
        return [self.mail_address!] //TODO ADD CNCONTACT
        
    }
}

private func isEmpty(contact: EnzevalosContact)-> Bool{
    if(contact.getFromMails().count == 0){
        return true
    }
    return false

}

func ==(lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    if isEmpty(lhs){
        return false
    }
    if isEmpty(rhs){
        return false
    }
    
    return lhs.getFromMails().first!.date == rhs.getFromMails().first!.date
}

func <(lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    print("LHS "+lhs.displayname!)
    print("RHS"+rhs.displayname!)
    if isEmpty(lhs){
        return true
    }
    if isEmpty(rhs){
        return false
    }
    print("\(lhs.getFromMails().first!.timeString) >? \( rhs.getFromMails().first!.timeString)")
    return lhs.getFromMails().first!.date > rhs.getFromMails().first!.date
}



