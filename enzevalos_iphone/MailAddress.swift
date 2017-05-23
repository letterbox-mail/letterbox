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
    var label: CNLabeledValue<NSString>{get} //FIXME: ist der NSString hier wirklich richtig? (http://stackoverflow.com/questions/39648830/how-to-add-new-email-to-cnmutablecontact-in-swift-3)
    var prefEnc: Bool{get set}
    var hasKey: Bool{get}
    
    var keyID: String?{get}
    var contact: EnzevalosContact?{get}
}
