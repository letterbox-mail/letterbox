//
//  EnzevalosContact.swift
//  readView
//
//  Created by Joscha on 12.09.16.
//  Copyright © 2016 Joscha. All rights reserved.
//

import Foundation
import Contacts

class EnzevalosContact: Comparable {
    let contact: CNContact
    var mails: [Mail] {
        didSet {
            self.mails.sortInPlace()
        }
    }
    
    var isVerified: Bool
    
    init(contact: CNContact, mails: [Mail]) {
        self.contact = contact
        self.mails = mails.sort()
        self.isVerified = false
    }
}

func ==(lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    return lhs.mails.first!.time == rhs.mails.first!.time
}

func <(lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    return lhs.mails.first!.time > rhs.mails.first!.time
}
