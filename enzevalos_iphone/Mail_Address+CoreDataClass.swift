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

    public var primaryKey: PersistentKey? {
        get {
            if hasKey {
                for key in publicKeys {
                    if key.keyID == primaryKeyID {
                        return key
                    }
                }
            }
            return nil
        }
    }

    open var publicKeys: Set<PersistentKey> {
        get {
            if let pks = keys {
                if let publicKeys = pks as? Set<PersistentKey> {
                    return publicKeys
                }
            }
            return Set<PersistentKey>()
        }
    }



    open var mailAddress: String {
        return address.lowercased()
    }

    open var label: CNLabeledValue<NSString> {
        if let cnc = self.contact?.cnContact {
            for adr in cnc.emailAddresses {
                if adr.value as String == address {
                    return adr
                }
            }
        }
        return CNLabeledValue.init(label: CNLabelOther, value: address as NSString)
    }



    open var hasKey: Bool {
        if publicKeys.count > 0 {
            return true
        }
        return false
    }
}
