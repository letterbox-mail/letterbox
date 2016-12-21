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
    let isSecure: Bool
    var mails: [Mail] {
        didSet {
            self.mails.sortInPlace()
        }
    }
    
    var isVerified: Bool {
        didSet {
            if !isSecure { // only secure mails can be verified
                isVerified = false
            }
        }
    }
    
    init(contact: CNContact, mails: [Mail], isSecure: Bool) {
        self.contact = contact
        self.mails = mails.sort()
        self.isSecure = isSecure

        self.isVerified = false
    }
}

func ==(lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    return lhs.mails.first!.time == rhs.mails.first!.time
}

func <(lhs: EnzevalosContact, rhs: EnzevalosContact) -> Bool {
    return lhs.mails.first!.time > rhs.mails.first!.time
}
