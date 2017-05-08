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


@objc(EnzevalosContact)
open class EnzevalosContact: NSManagedObject, Contact, Comparable {
        
    open var name:String{
        get{
            return getName()
        }
    }
    
    
    open var to: [Mail]{
        get{
            var mails = [Mail]()
            if let adrs = addresses{
                for adr in adrs{
                    let a  = adr as! Mail_Address
                    if a.to != nil {
                        for m in a.to!{
                            mails.append(m as! Mail)
                        }
                    }
                }
            }
            return mails
        }
    }
    
    open var bcc: [Mail]{
        get{
            var mails = [Mail]()
            if let adrs = addresses{
                for adr in adrs{
                    let a  = adr as! Mail_Address
                    if a.bcc != nil {
                        for m in a.bcc!{
                            mails.append(m as! Mail)
                        }
                    }
                }
            }
            return mails
        }
    }
    
    
    
    open var cc: [Mail]{
        get{
            var mails = [Mail]()
            if let adrs = addresses{
                for adr in adrs{
                    let a  = adr as! Mail_Address
                    if a.cc != nil {
                        for m in a.cc!{
                            mails.append(m as! Mail)
                        }
                    }
                }
            }
            return mails
        }
    }
    
    open var from: [Mail]{
        get{
            var mails = [Mail]()
            if let adrs = addresses{
                for adr in adrs{
                    let a  = adr as! Mail_Address
                    if a.from != nil {
                        for m in a.from!{
                            mails.append(m as! Mail)
                        }
                    }
                }
            }
            return mails
        }
    }
    
    open var records: [KeyRecord] {
        get{
            var myrecords = [KeyRecord]()
            for r in DataHandler.handler.receiverRecords{
                if r.ezContact == self{
                    myrecords.append(r)
                }
            }
            return myrecords
        
        }
    
    }
    open var hasKey: Bool{
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
    
    open var cnContact: CNContact?{
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
                let nameArray = n.characters.split(separator: " ").map(String.init)
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
            if let adrs = self.addresses{
                 adr = adrs.anyObject() as! Mail_Address
                con.emailAddresses.append(CNLabeledValue(label: CNLabelOther, value: adr.address as NSString))
            }
           
            
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
    
    func getAddress(_ address: String)-> Mail_Address?{
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
    
    func getAddressByMCOAddress(_ mcoaddress: MCOAddress)-> Mail_Address?{
        if (mcoaddress.mailbox) != nil{
            return getAddress(mcoaddress.mailbox.lowercased())
        }
        return nil
    }
    
    open func getMailAddresses()->[MailAddress]{
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

private func isEmpty(_ contact: EnzevalosContact)-> Bool{
    let mails = contact.from
        if(mails.count == 0){
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
    let mailLHS = lhs.from.last
    let mailRHS = rhs.from.last
    
    return mailLHS == mailRHS
}

public  func <(lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    if isEmpty(lhs){
        return true
    }
    if isEmpty(rhs){
        return false
    }
    let mailLHS = lhs.from.last
    let mailRHS = rhs.from.last
    
    return mailLHS < mailRHS
}
