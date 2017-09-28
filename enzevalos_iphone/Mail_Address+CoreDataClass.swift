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
open class Mail_Address: NSManagedObject, MailAddress {

    open var mailAddress: String {
        return address.lowercased()
    }

    open var label: CNLabeledValue<NSString> { //Wie in MailAddress; Ist der NSString hier richtig? (http://stackoverflow.com/questions/39648830/how-to-add-new-email-to-cnmutablecontact-in-swift-3)
        if let cnc = self.contact?.cnContact {
            for adr in cnc.emailAddresses {
                if adr.value as String == address {
                    return adr
                }
            }
        }
        return CNLabeledValue.init(label: CNLabelOther, value: address as NSString)
    }

    
    open var Key: PersistentKey?{
        if hasKey{
            return self.key?.anyObject() as? PersistentKey
        }
        return nil
    }

    
    open var hasKey: Bool {
        if key != nil && (key?.count)! > 0{
            return true
        }
        return false
    }
}
