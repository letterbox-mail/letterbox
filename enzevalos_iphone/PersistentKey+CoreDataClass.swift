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
    
    /*
 discoveryDate = Date.init() as NSDate
 firstMail = mail
 addToMailaddress(adr)
 self.keyID = keyID
 */
 
    open var prefEnc: EncState {
        get{
            return prefer_encryption
        }
        set{
            prefer_encryption = newValue
        }
    }
    
    func verify(){
        self.verifiedDate = Date.init() as NSDate
    }
    
    func isVerified() -> Bool{
        return self.verifiedDate != nil
    }
    
    func isExpired()-> Bool{
        // TODO: Consider different cryptotypes!
        let pgp = SwiftPGP()
        if let key = pgp.loadKey(id: self.keyID){
            if let expire = key.expirationDate{
                return expire < Date.init()
            }
           return false
        }
        return true
    }
    
    
}
