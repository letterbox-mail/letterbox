//
//  PGPKeyManagement.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 19.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

class PGPKeyManagement {
    
    let encryption: PGPEncryption
    let encryptionHandler: EncryptionHandler
    private var keyIDs : [String : [String]] = [:] //[mailAddress: keyIDs]
    private var addresses : [String: [String]] = [:] //[keyID : mailAddresses]
    
    init(encryption: PGPEncryption, encryptionHandler: EncryptionHandler) {
        self.encryption = encryption
        self.encryptionHandler = encryptionHandler
        //get or create keyIDs
        var data = self.encryptionHandler.getPersistentData("keyIDs", encryptionType: self.encryption.encryptionType)
        if let unwrappedData = data {
            self.keyIDs = NSKeyedUnarchiver.unarchiveObjectWithData(unwrappedData) as! [String: [String]]
        }
        else {
            data = NSKeyedArchiver.archivedDataWithRootObject(keyIDs)
            self.encryptionHandler.addPersistentData(data!, searchKey: "keyIDs", encryptionType: self.encryption.encryptionType, callBack: nil)
        }
        data = self.encryptionHandler.getPersistentData("addresses", encryptionType: self.encryption.encryptionType)
        if let unwrappedData = data {
            self.addresses = NSKeyedUnarchiver.unarchiveObjectWithData(unwrappedData) as! [String: [String]]
        }
        else {
            data = NSKeyedArchiver.archivedDataWithRootObject(addresses)
            self.encryptionHandler.addPersistentData(data!, searchKey: "addresses", encryptionType: self.encryption.encryptionType, callBack: nil)
        }
    }
    
    func getMaxIndex(fingerprint: String) -> Int64 {
        var index : Int64 = 0
        if let indexData = encryptionHandler.getPersistentData(fingerprint+"-index", encryptionType: self.encryption.encryptionType){
            indexData.getBytes(&index, length: sizeof(Int64))
        }
        
        return index
    }
    
    func addKey(key: PGPKeyWrapper, forMailAddresses: [String], callBack: ((success: Bool) -> Void)?) -> String{
        var index : Int64 = 0
        let searchKey = key.key.keyID.longKeyString+"-index"
        var existent = false
        if let indexData = encryptionHandler.getPersistentData(searchKey, encryptionType: self.encryption.encryptionType){
            existent = true
            indexData.getBytes(&index, length: sizeof(Int64))
        }
        
        index += 1
        let indexData = NSData(bytes: &index, length: sizeof(Int64))
        if !existent {
            encryptionHandler.addPersistentData(indexData, searchKey: searchKey, encryptionType: self.encryption.encryptionType, callBack: nil)
        }
        else {
            encryptionHandler.replacePersistentData(searchKey, replacementData: indexData, encryptionType: self.encryption.encryptionType, callBack: nil)
        }
        
        let keyID = key.key.keyID.longKeyString+"-"+String(index)
        key.setOnceKeyID(keyID)
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(key)
        encryptionHandler.addPersistentData(data, searchKey: key.keyID, encryptionType: self.encryption.encryptionType, callBack: callBack)
        
        addMailAddressesForKey(forMailAddresses, keyID: keyID)
        
        return keyID
    }
    
    func updateKey(key: PGPKeyWrapper, callBack: ((success: Bool) -> Void)?) {
        if encryptionHandler.hasPersistentData(key.keyID, encryptionType: self.encryption.encryptionType) {
            let keyData = NSKeyedArchiver.archivedDataWithRootObject(key)
            encryptionHandler.replacePersistentData(key.keyID, replacementData: keyData, encryptionType: self.encryption.encryptionType, callBack: callBack)
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
    
    func getMailAddressesForKeyID(keyID: String) -> [String]?{
        return addresses[keyID]
    }
    
    private func saveDictionarys(){
        var data = NSKeyedArchiver.archivedDataWithRootObject(keyIDs)
        encryptionHandler.replacePersistentData("keyIDs", replacementData: data, encryptionType: self.encryption.encryptionType, callBack: nil)
        data = NSKeyedArchiver.archivedDataWithRootObject(addresses)
        encryptionHandler.replacePersistentData("addresses", replacementData: data, encryptionType: self.encryption.encryptionType, callBack: nil)
    }
}
