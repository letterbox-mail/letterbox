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
            return label.label!
        }
    }
    public var label: CNLabeledValue{
        get{
            return self.label
        }
        set{
            self.label = newValue
        }
    }
    public var prefEnc: Bool{
        get{
            return false
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