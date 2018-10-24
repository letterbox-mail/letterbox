//
//  Mail_Address+CoreDataClass.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 05/01/17.
//  Copyright © 2018 fu-berlin.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
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
