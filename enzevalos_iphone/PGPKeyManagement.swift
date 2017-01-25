//
//  PGPKeyManagement.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 19.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

class PGPKeyManagement {
    
    let encryptionType: EncryptionType
    let encryptionHandler: EncryptionHandler
    let pgp: ObjectivePGP
    private var keyIDs : [String : [String]] = [:] //[mailAddress: keyIDs]
    private var addresses : [String: [String]] = [:] //[keyID : mailAddresses]
    
    init(encryptionHandler: EncryptionHandler) {
        self.encryptionType = EncryptionType.PGP
        self.encryptionHandler = encryptionHandler
        //get or create keyIDs
        var data = self.encryptionHandler.getPersistentData("keyIDs", encryptionType: self.encryptionType)
        if let unwrappedData = data {
            self.keyIDs = NSKeyedUnarchiver.unarchiveObjectWithData(unwrappedData) as! [String: [String]]
        }
        else {
            data = NSKeyedArchiver.archivedDataWithRootObject(keyIDs)
            self.encryptionHandler.addPersistentData(data!, searchKey: "keyIDs", encryptionType: self.encryptionType, callBack: nil)
        }
        data = self.encryptionHandler.getPersistentData("addresses", encryptionType: self.encryptionType)
        if let unwrappedData = data {
            self.addresses = NSKeyedUnarchiver.unarchiveObjectWithData(unwrappedData) as! [String: [String]]
        }
        else {
            data = NSKeyedArchiver.archivedDataWithRootObject(addresses)
            self.encryptionHandler.addPersistentData(data!, searchKey: "addresses", encryptionType: self.encryptionType, callBack: nil)
        }
        self.pgp = ObjectivePGP.init()
    }
    
    func getMaxIndex(fingerprint: String) -> Int64 {
        var index : Int64 = 0
        if let indexData = encryptionHandler.getPersistentData(fingerprint+"-index", encryptionType: self.encryptionType){
            indexData.getBytes(&index, length: sizeof(Int64))
        }
        
        return index
    }
    
    func addKey(key: PGPKeyWrapper, forMailAddresses: [String], callBack: ((success: Bool) -> Void)?) -> String{
        var index : Int64 = 0
        let searchKey = key.key.keyID.longKeyString+"-index"
        var existent = false
        if let indexData = encryptionHandler.getPersistentData(searchKey, encryptionType: self.encryptionType){
            existent = true
            indexData.getBytes(&index, length: sizeof(Int64))
        }
        
        index += 1
        let indexData = NSData(bytes: &index, length: sizeof(Int64))
        if !existent {
            encryptionHandler.addPersistentData(indexData, searchKey: searchKey, encryptionType: self.encryptionType, callBack: nil)
        }
        else {
            encryptionHandler.replacePersistentData(searchKey, replacementData: indexData, encryptionType: self.encryptionType, callBack: nil)
        }
        
        let keyID = key.key.keyID.longKeyString+"-"+String(index)
        key.setOnceKeyID(keyID)
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(key)
        encryptionHandler.addPersistentData(data, searchKey: key.keyID, encryptionType: self.encryptionType, callBack: callBack)
        
        addMailAddressesForKey(forMailAddresses, keyID: keyID)
        
        return keyID
    }
    
    func updateKey(key: PGPKeyWrapper, callBack: ((success: Bool) -> Void)?) {
        if encryptionHandler.hasPersistentData(key.keyID, encryptionType: self.encryptionType) {
            let keyData = NSKeyedArchiver.archivedDataWithRootObject(key)
            encryptionHandler.replacePersistentData(key.keyID, replacementData: keyData, encryptionType: self.encryptionType, callBack: callBack)
            return
        }
        if let cb = callBack {
            cb(success: false)
        }
    }
    
    func addMailAddressesForKey(mailAddresses: [String], keyID: String){
        for addr in mailAddresses{
            let mailAddress = addr.lowercaseString
            //insert keyID in keyIDs
            if var keys = keyIDs[mailAddress]{
                if !keys.contains(keyID) {
                    keys.append(keyID)
                    keyIDs[mailAddress] = keys
                }
            }
            else {
                keyIDs[mailAddress] = [keyID]
            }
            //insert mailAddress in addresses
            if var mAddresses = addresses[keyID]{
                if !mAddresses.contains(mailAddress) {
                    mAddresses.append(mailAddress)
                    addresses[keyID] = mAddresses
                }
            }
            else {
                addresses[keyID] = [mailAddress]
            }
        }
        saveDictionarys()
    }
    
    func removeMailAddressesForKey(mailAddresses: [String], keyID: String) {
        for addr in mailAddresses{
            let mailAddress = addr.lowercaseString
            //remove keyID outof keyIDs
            if var keys = keyIDs[mailAddress]{
                if keys.contains(keyID) {
                    keys.removeAtIndex(keys.indexOf(mailAddress)!)
                    keyIDs[mailAddress] = keys
                }
            }
            //remove mailAddress outof addresses
            if var mAddresses = addresses[keyID]{
                if mAddresses.contains(mailAddress) {
                    mAddresses.removeAtIndex(mAddresses.indexOf(keyID)!)
                    addresses[keyID] = mAddresses
                }
            }
        }
        saveDictionarys()
    }
    
    func getKeyIDsForMailAddress(mailAddress: String) -> [String]?{
        return keyIDs[mailAddress]
    }
    
    func getKey(keyID: String) -> PGPKeyWrapper? {
        if let data = (encryptionHandler.getPersistentData(keyID, encryptionType: self.encryptionType)) {
            let keywrapper = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? PGPKeyWrapper
            return keywrapper
        }
        return nil
    }
    
    func getMailAddressesForKeyID(keyID: String) -> [String]?{
        return addresses[keyID]
    }
    
    func removeKey(keyID: String, callBack: ((success: Bool) -> Void)?) {
        var addrs: [String] = []
        if let addrss = addresses[keyID] {
            addrs = addrss
        }
        self.removeMailAddressesForKey(addrs, keyID: keyID)
        encryptionHandler.deletePersistentData(keyID, encryptionType: EncryptionType.PGP, callBack: callBack)
    }
    
    private func saveDictionarys(){
        var data = NSKeyedArchiver.archivedDataWithRootObject(keyIDs)
        encryptionHandler.replacePersistentData("keyIDs", replacementData: data, encryptionType: self.encryptionType, callBack: nil)
        data = NSKeyedArchiver.archivedDataWithRootObject(addresses)
        encryptionHandler.replacePersistentData("addresses", replacementData: data, encryptionType: self.encryptionType, callBack: nil)
    }
}
