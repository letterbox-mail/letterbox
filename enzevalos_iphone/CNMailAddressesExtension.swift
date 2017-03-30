//
//  CNMailAddressesExtension.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Contacts

public class CNMailAddressExtension: MailAddress{

    public var mailAddress:String{
        get{
            return label.value as! String
        }
    }
    public var label: CNLabeledValue
    
    public var prefEnc: Bool{
        get{
            return false
        }
        set{
        }
    }
    public var hasKey: Bool{
        get{
            return false
        }
    }
    
    init(addr: CNLabeledValue){
        self.label = addr
    }
}
