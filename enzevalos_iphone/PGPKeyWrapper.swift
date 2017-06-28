//
//  KeyWrapper.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 16.11.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation

open class PGPKeyWrapper : NSObject, KeyWrapper {
    
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
    
    open var expireDate: Date?{
        get{
            // Expire date is not speficied for PublicKeyPacket V4.
            // See: https://tools.ietf.org/html/rfc4880#section-5.5.1.1
            if let publicKey = publicKeyPacket{
                // TODO: Consider other packets?
                if publicKey.v3validityPeriod <= 0{
                    return nil
                }
                else{
                    return (Calendar.current as NSCalendar).date(byAdding: .day, value: Int(publicKey.v3validityPeriod), to: publicKey.createDate, options: [])
                }
            }
            return nil
        }
    }
    
    open var creationDate: Date{
        get{
            // TODO: Consider other packets?
            if let publicKey = publicKeyPacket{
                return publicKey.createDate
            }
            return discoveryTime
        }
    }
    
    private var publicKeyPacket: PGPPublicKeyPacket?{
        get{
            if self.key.primaryKeyPacket.tag.rawValue == 6{ // Flag for PGPPublicKeyPacket
                let primKey = self.key.primaryKeyPacket as! PGPPublicKeyPacket
                return primKey
            }
            for k in key.allKeyPackets(){
                let keypacket = k as! PGPPacket
                if keypacket.tag.rawValue == 6 {
                    let publicKeyPacket = keypacket as! PGPPublicKeyPacket
                    return publicKeyPacket
                }
            }
            return nil
        }
    }
    
    
    open var revoked: Bool{
        didSet {
            self.revokeTime = Date.init()
            self.keyManager.updateKey(self)
        }
    }
    
    open fileprivate(set) var revokeTime: Date?
    
    //choose Int8 here?
    open var trustlevel: Int{
        didSet {
            self.keyManager.updateKey(self)
        }
    } //negative misstrust; zero neutral; positive trust
    
    open var verified: Bool{
        didSet {
            self.verifyTime = Date.init()
            self.keyManager.updateKey(self)
        }
    }
    
    open fileprivate(set) var verifyTime: Date?
    open let discoveryTime: Date
    
    //TODO
    open let discoveryMailUID: UInt64?
    
    open let type: EncryptionType = EncryptionType.PGP

    open fileprivate(set) var keyID: String //will look like key.longKeyString+"-1" for the key with this longKeyString at index 1
    
    open fileprivate(set) var fingerprint: String
    
    fileprivate let keyManager: PGPKeyManagement
    
    open var mailAddresses : [String]? {
        get {
            return self.keyManager.getMailAddressesForKeyID(self.keyID)
        }
        set(newArray) {
            var added: [String] = []
            var deleted: [String] = []
            
            if var arr = newArray {
                if var addrs = mailAddresses {
                    for entry in arr {
                        if addrs.contains(entry){
                            addrs.remove(at: addrs.index(of: entry)!)
                            arr.remove(at: arr.index(of: entry)!)
                        }
                    }
                    deleted = addrs
                }
                added = arr
            }
            else {
                if let addrs = mailAddresses {
                    deleted = addrs
                }
            }
            keyManager.addMailAddressesForKey(added, keyID: self.keyID)
            keyManager.removeMailAddressesForKey(deleted, keyID: self.keyID)
        }
    }
    
    //TODO
    //KeyIDs from previous keys, that signed the actual key
    //public var predecessorsKeyID: [String]?
    
    open var mailAddressesInKey: [String]? {
        get {
            var array: [String] = []
            for user:PGPUser in key.users as NSArray as! [PGPUser]{
                array.append(user.userID)
            }
            if array == [] {
                return nil
            }
            return array
        }
    }
    
    init(key: PGPKey, mailAddresses: [String], discoveryMailUID: UInt64?, keyManager: PGPKeyManagement){
        self.key = key
        self.keyManager = keyManager
        self.discoveryTime = Date.init()
        self.discoveryMailUID = discoveryMailUID
        self.keyID = ""
        do {
            try self.fingerprint = PGPFingerprint.init(data: key.export()).description
        }
        catch {
            self.fingerprint = "Error" //TODO: find a secure way
        }
        revoked = false
        trustlevel = 0
        verified = false
        super.init()
        
        self.keyManager.addKey(self, forMailAddresses: mailAddresses)
    }
    
    required public init(coder: NSCoder){
        let enc : PGPEncryption = EnzevalosEncryptionHandler.getEncryption(self.type)! as! PGPEncryption
        keyManager = (enc as PGPEncryption).getPGPKeyManagement()//coder.decodeObjectForKey("keyManager") as! PGPKeyManagement
        key = keyManager.pgp.keys(from: coder.decodeObject(forKey: "key") as! Data)![0]
        revoked = coder.decodeBool(forKey: "revoked")
        revokeTime = coder.decodeObject(forKey: "revokeTime") as! Date?
        trustlevel = coder.decodeInteger(forKey: "trustlevel")
        verified = coder.decodeBool(forKey: "verified")
        verifyTime = coder.decodeObject(forKey: "verifyTime") as! Date?
        keyID = coder.decodeObject(forKey: "keyID") as! String
        fingerprint = coder.decodeObject(forKey: "fingerprint") as! String
        if let dmailUID = coder.decodeObject(forKey: "discoveryMailUID"){
            self.discoveryMailUID = (dmailUID as! NSNumber).uint64Value
        }
        else {
            self.discoveryMailUID = nil
        }
        discoveryTime = coder.decodeObject(forKey: "discoveryTime") as! Date
    }
    
    open func setOnceKeyID (_ keyID: String) {
        if self.keyID == "" {
            self.keyID = keyID
        }
    }
    
    open func encodeWithCoder(_ coder: NSCoder){
        coder.encode((try? key.export())!, forKey: "key")
        coder.encode(revoked, forKey: "revoked")
        coder.encode(revokeTime, forKey: "revokeTime")
        coder.encode(trustlevel, forKey: "trustlevel")
        coder.encode(verified, forKey: "verified")
        coder.encode(verifyTime, forKey: "verifyTime")
        if let dmailUID = discoveryMailUID {
            coder.encode(NSNumber.init(value: dmailUID as UInt64), forKey: "discoveryMailUID")
        }
        coder.encode(keyID, forKey: "keyID")
        coder.encode(fingerprint, forKey: "fingerprint")
        coder.encode(discoveryTime, forKey: "discoveryTime")
    }
    
}
