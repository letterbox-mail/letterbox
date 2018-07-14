//
//  CNMailAddressesExtension.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
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
    open var label: CNLabeledValue<NSString> //FIXME: NSString hier richtig?

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

    init(addr: CNLabeledValue<NSString>) { //FIXME: NSString hier richtig?
        self.label = addr
        self.publicKeys = Set<PersistentKey>()
    }

    convenience init(addr: NSString) { //FIXME: manuell: String -> NSString
        self.init(addr: CNLabeledValue(label: CNLabelOther, value: addr))
    }
}
