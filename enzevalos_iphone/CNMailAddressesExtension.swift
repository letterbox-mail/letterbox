//
//  CNMailAddressesExtension.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10/01/17.
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
//

import Foundation
import Contacts

open class CNMailAddressExtension: MailAddress {
    public var primaryKey: PersistentKey?

    public var publicKeys: Set<PersistentKey>


    open var mailAddress: String {
        get {
            return label.value as String
        }
    }
    open var label: CNLabeledValue<NSString> 

    open var prefEnc: EncState {
        get {
            return EncState.NOAUTOCRYPT
        }
        set {
        }
    }
    open var hasKey: Bool {
        get {
            return false
        }
    }


    open var Key: PersistentKey? {
        get {
            return nil
        }
    }

    open var contact: EnzevalosContact? {
        get {
            return nil
        }
    }

    init(addr: CNLabeledValue<NSString>) {
        self.label = addr
        self.publicKeys = Set<PersistentKey>()
    }

    convenience init(addr: NSString) {
        self.init(addr: CNLabeledValue(label: CNLabelOther, value: addr))
    }
}
