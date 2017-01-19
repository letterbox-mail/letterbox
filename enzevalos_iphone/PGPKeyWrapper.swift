//
//  KeyWrapper.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 16.11.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation

public class PGPKeyWrapper : NSObject, KeyWrapper {
    
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
    
    public var revoked: Bool{
        didSet {
            let handler = KeyHandler.getHandler()
            handler.updateKey(self)
        }
    }
    
    public private(set) var revokeTime: NSDate {
        get {
            
        }
        set {
        
        }
    }
    
    //choose Int8 here?
    public var trustlevel: Int{
        didSet {
            let handler = KeyHandler.getHandler()
            handler.updateKey(self)
        }
    } //negative misstrust; zero neutral; positive trust
    
    public var verified: Bool{
        didSet {
            let handler = KeyHandler.getHandler()
            handler.updateKey(self)
        }
    }
    
    public private(set) var verifyTime: NSDate {
        get {
            
        }
        set {
            
        }
    }
    
    public let discoveryTime: NSDate
    
    public let discoveryMailUID: UInt64?

    public let keyID: String
    
    private let encrytion: PGPEncryption
    
    //KeyIDs from previous keys, that signed the actual key
    public var predecessorsKeyID: [UInt64]?
    
    init(key: PGPKey, mailaddress: String, encryption: PGPEncryption){
        self.key = key
        
        self.keyID = self.key.keyID.longKeyString  //self.key
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
    
    required public init(coder: NSCoder){
        key = CryptoHandler.getHandler().pgp.keysFromData(coder.decodeObjectForKey("key") as! NSData)![0]
        revoked = coder.decodeBoolForKey("revoked")
        revokeTime = coder.decodeObjectForKey("revokeTime") as! NSDate
        trustlevel = coder.decodeIntegerForKey("trustlevel")
        verified = coder.decodeBoolForKey("verified")
        keyID = coder.decodeInt64ForKey("keyID")
        
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
    
    public func encodeWithCoder(coder: NSCoder){
        coder.encodeObject((try? key.export())!, forKey: "key")
        coder.encodeBool(revoked, forKey: "revoked")
        coder.encodeObject(revokeTime, forKey: "revokeTime")
        coder.encodeInteger(trustlevel, forKey: "trustlevel")
        coder.encodeBool(verified, forKey: "verified")
        coder.encodeObject(verifyTime, forKey: "verifyTime")
        //coder.encodeObject(NSNumber(unsignedLongLong: keyID), forKey: "keyID")
        coder.encodeInt64(Int64(keyID), forKey: "keyID")
        coder.encodeObject(discoveryTime, forKey: "discoveryTime")
    }
    
}
