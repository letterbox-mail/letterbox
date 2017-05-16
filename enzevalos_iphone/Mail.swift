//
//  Mail.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 16/05/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation


public protocol MailProtocol{
    
    
    var cc: NSSet? {get}
    var bcc: NSSet? {get}
    var from: MailAddress {get}
    var to: NSSet {get}
    var date: Date{get}
    var subject: String?{get}
    var body: String?{get}
        
}
