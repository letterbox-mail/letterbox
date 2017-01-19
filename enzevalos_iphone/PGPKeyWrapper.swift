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
            self.revokeTime = NSDate.init()
            self.keyManager.updateKey(self, callBack: nil)
        }
    }
    
    public private(set) var revokeTime: NSDate?
    
    //choose Int8 here?
    public var trustlevel: Int{
        didSet {
            self.keyManager.updateKey(self, callBack: nil)
        }
    } //negative misstrust; zero neutral; positive trust
    
    public var verified: Bool{
        didSet {
            self.verifyTime = NSDate.init()
            self.keyManager.updateKey(self, callBack: nil)
        }
    }
    
    public private(set) var verifyTime: NSDate?
    public let discoveryTime: NSDate
    
    //TODO
    //public let discoveryMailUID: UInt64?

    public private(set) var keyID: String
    
    private let keyManager: PGPKeyManagement
    
    public var mailAddresses : [String]? {
        get {
            return self.keyManager.getMailAddressesForKeyID(self.keyID)
        }
        /*set(newArray) {
            var added: [String] = []
            var deleted: [String] = []
            var remained: [String] = []
            for entry in newArray {
                if entry
            }
        }*/
    }
    
    //TODO
    //KeyIDs from previous keys, that signed the actual key
    //public var predecessorsKeyID: [String]?
    
    init(key: PGPKey, mailAddresses: [String], discoveryMailUID: UInt64, keyManager: PGPKeyManagement){
        self.key = key
        self.keyManager = keyManager
        self.discoveryTime = NSDate.init()
        self.keyID = ""
        revoked = false
        trustlevel = 0
        verified = false
        
        self.keyManager.addKey(self, forMailAddresses: mailAddresses, callBack: nil)
    }
    
    required public init(coder: NSCoder){
        key = CryptoHandler.getHandler().pgp.keysFromData(coder.decodeObjectForKey("key") as! NSData)![0]
        revoked = coder.decodeBoolForKey("revoked")
        revokeTime = coder.decodeObjectForKey("revokeTime") as! NSDate?
        trustlevel = coder.decodeIntegerForKey("trustlevel")
        verified = coder.decodeBoolForKey("verified")
        verifyTime = coder.decodeObjectForKey("verifyTime") as! NSDate?
        keyID = coder.decodeObjectForKey("keyID") as! String
        
        
    }
    
    public func setOnceKeyID (keyID: String) {
        if self.keyID == "" {
            self.keyID = keyID
        }
    }
    
    public func encodeWithCoder(coder: NSCoder){
        coder.encodeObject((try? key.export())!, forKey: "key")
        coder.encodeBool(revoked, forKey: "revoked")
        coder.encodeObject(revokeTime, forKey: "revokeTime")
        coder.encodeInteger(trustlevel, forKey: "trustlevel")
        coder.encodeBool(verified, forKey: "verified")
        coder.encodeObject(verifyTime, forKey: "verifyTime")
        //coder.encodeObject(NSNumber(unsignedLongLong: keyID), forKey: "keyID")
        coder.encodeObject(keyID, forKey: "keyID")
        coder.encodeObject(discoveryTime, forKey: "discoveryTime")
    }
    
}
