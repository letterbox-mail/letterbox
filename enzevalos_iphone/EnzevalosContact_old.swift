//
//  EnzevalosContact.swift
//  readView
//
//  Created by Joscha on 12.09.16.
//  Copyright © 2016 Joscha. All rights reserved.
//

import Foundation
import Contacts
import CoreData

class EnzevalosContact_old {
    let contact: CNContact
    let displayname: String
    let mailaddress: String
    var prefer_encryption: Bool
    var isVerified: Bool

    
    
    var from_mails: [Mail] {
        didSet {
            self.from_mails.sortInPlace()
        }
    }
    
    
    init(contact: CNContact, from_mails: [Mail], displayname: String, mailaddress: String, prefer_encryption: Bool, isVerfied: Bool) {
        self.contact = contact
        self.from_mails = from_mails.sort()
        self.displayname = displayname
        self.mailaddress = mailaddress
        self.prefer_encryption = prefer_encryption
        self.isVerified = isVerfied
        
    }
   
    
}
/*

func ==(lhs: EnzevalosContact_old, rhs: EnzevalosContact_old) -> Bool {
    return lhs.from_mails.first!.time == rhs.from_mails.first!.time
}

func <(lhs: EnzevalosContact_old, rhs: EnzevalosContact_old) -> Bool {
    return lhs.from_mails.first!.time > rhs.from_mails.first!.time
}
 */
