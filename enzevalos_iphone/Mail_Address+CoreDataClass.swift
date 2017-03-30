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

    public var mailAddress: String {
        return address
    }

    public var label: CNLabeledValue {
        if let cnc = self.contact.cnContact {
            for adr in cnc.emailAddresses {
                if adr.value as! String == address {
                    return adr
                }
            }
        }
        return CNLabeledValue.init(label: CNLabelOther, value: address)
    }

    public var prefEnc: Bool {
        get{
            return prefer_encryption
        }
        set{
            prefer_encryption = newValue
        }
    }

    //TODO think about it!
    public var keyID: String? {
        get {
            if let encryption = EnzevalosEncryptionHandler.getEncryption(self.encryptionType) {
                return encryption.getActualKeyID(self.address)
            }
            return nil
        }
        set (newID) {
            if let id = newID {
                if let encryption = EnzevalosEncryptionHandler.getEncryption(self.encryptionType) {
                    if encryption.keyIDExists(id) {
                        if let currentID = self.keyID {
                            encryption.removeMailAddressForKey(self.mailAddress, keyID: currentID)
                        }
                        encryption.addMailAddressForKey(mailAddress, keyID: id)
                    }
                }
            }
                else {
                if let encryption = EnzevalosEncryptionHandler.getEncryption(self.encryptionType) {
                    if let currentID = self.keyID {
                        encryption.removeMailAddressForKey(self.mailAddress, keyID: currentID)
                    }
                }
            }
        }
    }

    public var hasKey: Bool {
        if let encryption = EnzevalosEncryptionHandler.getEncryption(self.encryptionType) {
            return encryption.hasKey(self.mailAddress)
        }
        return false
    }
}
