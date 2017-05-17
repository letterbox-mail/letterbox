//
//  EphemeralMail.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 17/05/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
open class EphemeralMail: Mail{

    
    
    
    public var cc: NSSet?
    public var bcc: NSSet?
    public var from: MailAddress
    public var to: NSSet
    public var date: Date
    public var subject: String?
    public var body: String?
    public var uid: UInt64
    
    
    public init(from: MailAddress, to: [MailAddress], cc: [MailAddress], bcc: [MailAddress], date: Date, subject: String?, body: String?, uid: UInt64){
        self.cc = NSMutableSet()
        self.cc?.addingObjects(from: cc)
        self.bcc = NSMutableSet()
        self.bcc?.addingObjects(from: bcc)
        self.from = from
        self.to = NSMutableSet()
        self.to.addingObjects(from: to)
        self.body = body
        self.date = date
        self.subject =  subject
        self.uid = uid
    }
    
    
    
    
}
