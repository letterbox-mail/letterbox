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
    private var actualPrivateKey: String?
    private var privateKeys: [String]
    
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
            self.encryptionHandler.addPersistentData(data!, searchKey: "keyIDs", encryptionType: self.encryptionType)
        }
        data = self.encryptionHandler.getPersistentData("addresses", encryptionType: self.encryptionType)
        if let unwrappedData = data {
            self.addresses = NSKeyedUnarchiver.unarchiveObjectWithData(unwrappedData) as! [String: [String]]
        }
        else {
            data = NSKeyedArchiver.archivedDataWithRootObject(addresses)
            self.encryptionHandler.addPersistentData(data!, searchKey: "addresses", encryptionType: self.encryptionType)
        }
        data = self.encryptionHandler.getPersistentData("actualPrivateKey", encryptionType: self.encryptionType)
        if let unwrappedData = data {
            self.actualPrivateKey = NSKeyedUnarchiver.unarchiveObjectWithData(unwrappedData) as? String
        }
        else {
            self.actualPrivateKey = nil
        }
        data = self.encryptionHandler.getPersistentData("privateKeys", encryptionType: self.encryptionType)
        if let unwrappedData = data {
            self.privateKeys = NSKeyedUnarchiver.unarchiveObjectWithData(unwrappedData) as! [String]
        }
        else {
            self.privateKeys = []
            let insertData = NSKeyedArchiver.archivedDataWithRootObject(self.privateKeys)
            encryptionHandler.addPersistentData(insertData, searchKey: "privateKeys", encryptionType: self.encryptionType)
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
    
    func addKey(key: PGPKeyWrapper, forMailAddresses: [String]) -> String{
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
            encryptionHandler.addPersistentData(indexData, searchKey: searchKey, encryptionType: self.encryptionType)
        }
        else {
            encryptionHandler.replacePersistentData(searchKey, replacementData: indexData, encryptionType: self.encryptionType)
        }
        
        let keyID = key.key.keyID.longKeyString+"-"+String(index)
        key.setOnceKeyID(keyID)
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(key)
        encryptionHandler.addPersistentData(data, searchKey: key.keyID, encryptionType: self.encryptionType)
        
        addMailAddressesForKey(forMailAddresses, keyID: keyID)
        
        addPrivateKey(key)
        
        return keyID
    }
    
    func updateKey(key: PGPKeyWrapper) {
        if encryptionHandler.hasPersistentData(key.keyID, encryptionType: self.encryptionType) {
            let keyData = NSKeyedArchiver.archivedDataWithRootObject(key)
            encryptionHandler.replacePersistentData(key.keyID, replacementData: keyData, encryptionType: self.encryptionType)
            return
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
    
    //keyID of the current used privateKey
    func getPrivateKeyID() -> String? {
        return actualPrivateKey
    }
    
    //a list of all privateKeyIDs, which are not removed
    func getAllPrivateKeyIDs() -> [String]? {
        if self.privateKeys.count == 0 {
            return nil
        }
        return self.privateKeys
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
    
    func keyIDExists(keyID: String) -> Bool {
        if let addr = addresses[keyID] {
            return addr != []
        }
        return false
    }
    
    //if the actualPrivateKey is removed a old key is set as actualPrivateKey, if availiable
    func removeKey(keyID: String) {
        removePrivateKey(keyID)
        
        var addrs: [String] = []
        if let addrss = addresses[keyID] {
            addrs = addrss
        }
        self.removeMailAddressesForKey(addrs, keyID: keyID)
        encryptionHandler.deletePersistentData(keyID, encryptionType: EncryptionType.PGP)
    }
    
    func useOnlyActualPrivateKey() {
        self.pgp.keys = []
        if let actual = self.actualPrivateKey {
            self.pgp.keys.append(self.getKey(actual)!.key)
        }
    }
    
    //will be deactivated if new private key is added or a private key is removed
    func useAllPrivateKeys() {
        for key in privateKeys {
            self.pgp.keys.append(self.getKey(key)!.key)
        }
    }
    
    private func saveDictionarys(){
        var data = NSKeyedArchiver.archivedDataWithRootObject(keyIDs)
        encryptionHandler.replacePersistentData("keyIDs", replacementData: data, encryptionType: self.encryptionType)
        data = NSKeyedArchiver.archivedDataWithRootObject(addresses)
        encryptionHandler.replacePersistentData("addresses", replacementData: data, encryptionType: self.encryptionType)
    }
    
    private func addPrivateKey(key: PGPKeyWrapper) {
        if key.key.type == PGPKeyType.Secret {
            privateKeys.append(key.keyID)
            var data = NSKeyedArchiver.archivedDataWithRootObject(privateKeys)
            encryptionHandler.replacePersistentData("privateKeys", replacementData: data, encryptionType: self.encryptionType)
            actualPrivateKey = key.keyID
            data = NSKeyedArchiver.archivedDataWithRootObject(actualPrivateKey!)
            if encryptionHandler.hasPersistentData("actualPrivateKey", encryptionType: self.encryptionType) {
                encryptionHandler.replacePersistentData("actualPrivateKey", replacementData: data, encryptionType: self.encryptionType)
            }
            else {
                encryptionHandler.addPersistentData(data, searchKey: "actualPrivateKey", encryptionType: self.encryptionType)
            }
            self.useOnlyActualPrivateKey()
        }
    }
    
    private func removePrivateKey(keyID: String) {
        if privateKeys.contains(keyID) {
            privateKeys.removeAtIndex(privateKeys.indexOf(keyID)!)
            actualPrivateKey = privateKeys.last
            if let key = actualPrivateKey {
                let data = NSKeyedArchiver.archivedDataWithRootObject(key)
                encryptionHandler.replacePersistentData("actualPrivateKey", replacementData: data, encryptionType: self.encryptionType)
            }
            else {
                encryptionHandler.deletePersistentData("actualPrivateKey", encryptionType: self.encryptionType)
            }
            let data = NSKeyedArchiver.archivedDataWithRootObject(privateKeys)
            encryptionHandler.addPersistentData(data, searchKey: "privateKeys", encryptionType: self.encryptionType)
            self.useOnlyActualPrivateKey()
        }
    }
}
