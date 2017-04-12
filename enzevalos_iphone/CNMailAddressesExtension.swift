//
//  CNMailAddressesExtension.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Contacts

open class CNMailAddressExtension: MailAddress{

    open var mailAddress:String{
        get{
            return label.value as String
        }
    }
    open var label: CNLabeledValue<NSString> //FIXME: NSString hier richtig?
    
    open var prefEnc: Bool{
        get{
            return false
        }
        set{
        }
    }
    open var hasKey: Bool{
        get{
            return false
        }
    }
    
    init(addr: CNLabeledValue<NSString>){ //FIXME: NSString hier richtig?
        self.label = addr
    }
    
    convenience init(addr: NSString){ //FIXME: manuell: String -> NSString
        self.init(addr: CNLabeledValue(label: CNLabelOther, value: addr))
    }
}
