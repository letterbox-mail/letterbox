//
//  MailAddress.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Contacts

public protocol MailAddress { 
    var mailAddress:String{get}
    var label: CNLabeledValue{get}
    var prefEnc: Bool{get set}
    var hasKey: Bool{get}
}
