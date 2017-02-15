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

@objc(EnzevalosContact)
public class EnzevalosContact: NSManagedObject, Contact, Comparable {
    
    //addKeyRecords
    
    public var name:String{
        get{
            return getName()
        }
    }
    
    public var records: [KeyRecord] = [KeyRecord]() //TODO: Handle duplicates
    
    public var hasKey: Bool{
        get {
            for item in addresses!{
                let adr = item as! MailAddress
                if adr.hasKey{
                    return true
                }
            }
            return false
        }
    }
    
    public var cnContact: CNContact?{
        get{
            let contactFromBook = AddressHandler.findContact(self)
            if contactFromBook.count > 0 {
                let con = contactFromBook.first
                self.cnidentifier = con?.identifier
                return con!
            }
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
            
            let adr: Mail_Address
            adr = self.addresses?.anyObject() as! Mail_Address
            con.emailAddresses.append(CNLabeledValue(label: CNLabelOther, value: adr.address))
            
            return con
        }
    }
    
    private func getName()-> String{
        var name: String
        name = String()
        if let cnc = cnContact{
            if cnc.givenName.characters.count > 0 {
                name += cnc.givenName
            }
            if cnc.familyName.characters.count > 0 {
                if name.characters.count > 0 {
                    name += " "
                }
                name += cnc.familyName
            }
        }
        if name.characters.count == 0{
            if displayname != nil{
                return displayname!
            }
            else{
                return "No name"
            }
        }
        return name
    }
    
    func getAddress(address: String)-> Mail_Address?{
        var addr: Mail_Address
        if addresses != nil {
            for obj in addresses! {
                addr = obj as! Mail_Address
                if(addr.address == address){
                    return addr
                }
            }
        }
        return nil
    }
    
    func getAddressByMCOAddress(mcoaddress: MCOAddress)-> Mail_Address?{
        return getAddress(mcoaddress.mailbox!)
    }
    
    public func getMailAddresses()->[MailAddress]{
        var adr = [MailAddress] ()
        if self.addresses != nil {
            for a in addresses!{
                let b = a as! Mail_Address
                adr.append(b)
            }
        }
        return adr
    }
}

private func isEmpty(contact: EnzevalosContact)-> Bool{
    if let mails = contact.from{
        if(mails.count == 0){
            return true
        }
        return false
    }
    return true
}

func ==(lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    if isEmpty(lhs){
        return false
    }
    if isEmpty(rhs){
        return false
    }
    let mailLHS = lhs.from?.lastObject as! Mail
    let mailRHS = rhs.from?.lastObject as! Mail
    
    return mailLHS == mailRHS
}

public  func <(lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    if isEmpty(lhs){
        return true
    }
    if isEmpty(rhs){
        return false
    }
    let mailLHS = lhs.from?.lastObject as! Mail
    let mailRHS = rhs.from?.lastObject as! Mail
    
    return mailLHS < mailRHS
}
