//
//  PersistentKey+CoreDataClass.swift
//
//
//  Created by Oliver Wiese on 27.09.17.
//
//

import Foundation
import CoreData

@objc(PersistentKey)
public class PersistentKey: NSManagedObject {

    var counterSignedMails: Int {
        if let signedMails = self.signedMails {
            return signedMails.count
        }
        return 0
    }

    func verify() {
        self.verifiedDate = Date.init()
    }

    func isVerified() -> Bool {
        return self.verifiedDate != nil
    }

    func isExpired() -> Bool {
        let pgp = SwiftPGP()
        if let key = pgp.loadKey(id: self.keyID) {
            if let expire = key.expirationDate {
                return expire < Date.init()
            }
            return false
        }
        return true
    }


}
