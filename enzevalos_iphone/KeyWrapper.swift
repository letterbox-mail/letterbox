//
//  KeyWrapper.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 16.11.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation

public class KeyWrapper : NSObject {
    
    let key: PGPKey /*{
        set (newKey) {
            oldKey = self.copy()
            self.key = newKey
            self.timestamp = NSDate.init()
            let handler = KeyHandler.createHandler()
            handler.updateKey(self)
        }
        get {
            return self.key
        }
    }*/
    //TODO Referenz auf Mail, die den key geändert hat, hinzufügen
    //darin befindet sich unter anderem auch, ob die ändernde Mail mit dem alten Key signiert war
    //private(set) var oldKey: KeyWrapper?
    
    //private(set) var alternativeOldKeys: [KeyWrapper]?
    
    var revoked: Bool{
        didSet {
            let handler = KeyHandler.getHandler()
            handler.updateKey(self)
        }
    }
    //choose Int8 here?
    var trustlevel: Int{
        didSet {
            let handler = KeyHandler.getHandler()
            handler.updateKey(self)
        }
    } //negative misstrust; zero neutral; positive trust
    var verified: Bool{
        didSet {
            let handler = KeyHandler.getHandler()
            handler.updateKey(self)
        }
    }
    let address: String /*[String]{
        set (newAddrs) {
            let handler = KeyHandler.createHandler()
            //oldKey = self.copy()
            
            /*for addr in newAddrs {
                if handler.getKeyByMailaddress(addr) != nil &&  {
                    
                }
            }*/
            //let handler = KeyHandler.createHandler()
            handler.updateKey(self)
        }
        get {
            return self.addresses
        }
    }*/
    let timestamp: NSDate // creation date of keywrapper object
    
    init(key: PGPKey, mailaddress: String){
        self.key = key
        //self.oldKey = nil
        revoked = false
        trustlevel = 0
        verified = false
        self.address = mailaddress
        self.timestamp = NSDate.init()
        
        /*let handler = KeyHandler.createHandler()
        for addr in addresses {
            handler.addKeyForMailaddress(addr, keyWrapper: self)
        }*/
    }
    
    init(coder: NSCoder){
        key = CryptoHandler.getHandler().pgp.keysFromData(coder.decodeObjectForKey("key") as! NSData)![0]
        revoked = coder.decodeBoolForKey("revoked")
        trustlevel = coder.decodeIntegerForKey("trustlevel")
        verified = coder.decodeBoolForKey("verified")
        address = coder.decodeObjectForKey("address") as! String
        timestamp = coder.decodeObjectForKey("timestamp") as! NSDate
    }
    
//    private init(key: PGPKey, oldKey: KeyWrapper?, alternativeOldKeys: [KeyWrapper]?,revoked: Bool, trustlevel: Int8, verified: Bool, addresses: [String], timestamp: NSDate){
//        //self.key = key
//        //self.oldKey = oldKey
//        //self.alternativeOldKeys = alternativeOldKeys
//        self.revoked = revoked
//        self.trustlevel = trustlevel
//        self.verified = verified
//        //self.addresses = addresses
//        self.timestamp = timestamp
//    }
    
    /*func copy() -> KeyWrapper {
        return KeyWrapper(key: self.key, oldKey: self.oldKey, alternativeOldKeys: self.alternativeOldKeys, revoked: self.revoked, trustlevel: self.trustlevel, verified: self.verified, addresses: self.addresses, timestamp: self.timestamp)
    }*/
    
    func encodeWithCoder(coder: NSCoder){
        coder.encodeObject((try? key.export())!, forKey: "key")
        coder.encodeBool(revoked, forKey: "revoked")
        coder.encodeInteger(trustlevel, forKey: "trustlevel")
        coder.encodeBool(verified, forKey: "verified")
        coder.encodeObject(address, forKey: "address")
        coder.encodeObject(timestamp, forKey: "timestamp")
        
    }
    
}
