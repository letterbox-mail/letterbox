//
//  EphemeralMail.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 17/05/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

open class EphemeralMail: Mail {
    
    public var cc: NSSet?
    public var bcc: NSSet?
    public var to: NSSet
    public var date: Date
    public var subject: String?
    public var body: String?
    public var uid: UInt64
    public var predecessor: PersistentMail?

    public init(to: NSSet, cc: NSSet, bcc: NSSet, date: Date, subject: String?, body: String?, uid: UInt64, predecessor: PersistentMail?) { //TODO: is casting cc and bcc necessary?
        self.cc = cc
        self.bcc = bcc
        self.to = to
        self.body = body
        self.date = date
        self.subject = subject
        self.uid = uid
        self.predecessor = predecessor
    }
}
