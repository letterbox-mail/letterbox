//
//  Mail_Address+CoreDataClass.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 05/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData
import Contacts

@objc(Mail_Address)
public class Mail_Address: NSManagedObject, MailAddress {
    
    public var mailAddress: String{
        get{
            return address
        }
    }
    
   public var label: CNLabeledValue{
        get{
            return CNLabeledValue.init(label: address, value: CNLabelHome)
        }
    }
    
    public var prefEnc: Bool{
        get{
            return prefer_encryption
        }
    }
    
    public var hasKey: Bool{
        get{
            return key != nil
        }
    }
    
}