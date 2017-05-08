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
            self.keyIDs = (NSKeyedUnarchiver.unarchiveObject(with: unwrappedData) as! NSDictionary) as! [String: [String]]
        }
        else {
            data = NSKeyedArchiver.archivedData(withRootObject: keyIDs)
            self.encryptionHandler.addPersistentData(data!, searchKey: "keyIDs", encryptionType: self.encryptionType)
        }
        data = self.encryptionHandler.getPersistentData("addresses", encryptionType: self.encryptionType)
        if let unwrappedData = data {
            self.addresses = (NSKeyedUnarchiver.unarchiveObject(with: unwrappedData) as! NSDictionary) as! [String: [String]]
        }
        else {
            data = NSKeyedArchiver.archivedData(withRootObject: addresses)
            self.encryptionHandler.addPersistentData(data!, searchKey: "addresses", encryptionType: self.encryptionType)
        }
        data = self.encryptionHandler.getPersistentData("actualPrivateKey", encryptionType: self.encryptionType)
        if let unwrappedData = data {
            self.actualPrivateKey = NSKeyedUnarchiver.unarchiveObject(with: unwrappedData) as? String
        }
        else {
            self.actualPrivateKey = nil
        }
        data = self.encryptionHandler.getPersistentData("privateKeys", encryptionType: self.encryptionType)
        if let unwrappedData = data {
            self.privateKeys = NSKeyedUnarchiver.unarchiveObject(with: unwrappedData) as! [String]
        }
        else {
            self.privateKeys = []
            let insertData = NSKeyedArchiver.archivedData(withRootObject: self.privateKeys)
            encryptionHandler.addPersistentData(insertData, searchKey: "privateKeys", encryptionType: self.encryptionType)
        }
        self.pgp = ObjectivePGP.init()
    }
    
    func getMaxIndex(_ fingerprint: String) -> Int64 {
        var index : Int64 = 0
        if let indexData = encryptionHandler.getPersistentData(fingerprint+"-index", encryptionType: self.encryptionType){
            (indexData as NSData).getBytes(&index, length: MemoryLayout<Int64>.size)
        }
        
        return index
    }
    
    @discardableResult func addKey(_ key: PGPKeyWrapper, forMailAddresses: [String]) -> String{
        var index : Int64 = 0
        let searchKey = key.key.keyID.longKeyString+"-index"
        var existent = false
        if let indexData = encryptionHandler.getPersistentData(searchKey, encryptionType: self.encryptionType){
            existent = true
            (indexData as NSData).getBytes(&index, length: MemoryLayout<Int64>.size)
        }
        
        index += 1
        let indexData = Data(bytes: &index, count: MemoryLayout<Int64>.size)//Data(bytes: UnsafePointer<UInt8>(&index), length: MemoryLayout<Int64>.size)
        if !existent {
            encryptionHandler.addPersistentData(indexData, searchKey: searchKey, encryptionType: self.encryptionType)
        }
        else {
            encryptionHandler.replacePersistentData(searchKey, replacementData: indexData, encryptionType: self.encryptionType)
        }
        
        let keyID = key.key.keyID.longKeyString+"-"+String(index)
        key.setOnceKeyID(keyID)
        
        let data = NSKeyedArchiver.archivedData(withRootObject: key)
        //key-ID should be created once
        //encryptionHandler.addPersistentData(data, searchKey: key.keyID, encryptionType: self.encryptionType)
        
        //check, if the key is already inserted
        var alreadyInserted = false
        var returnedKeyID = keyID
        if index > 1 {
            for otherIndex in 1...index {
                var otherKeyID = key.key.keyID.longKeyString+"-"+String(otherIndex)
                if key.key.isEqual(self.getKey(otherKeyID)?.key) {
                    alreadyInserted = true
                    returnedKeyID = otherKeyID
                    break
                }
            }
        }
        if !alreadyInserted {
            encryptionHandler.addPersistentData(data, searchKey: key.keyID, encryptionType: self.encryptionType)
            addMailAddressesForKey(forMailAddresses, keyID: keyID)
            addPrivateKey(key)
        }
        
        return returnedKeyID
    }
    
    
    func updateKey(_ key: PGPKeyWrapper) {
        if encryptionHandler.hasPersistentData(key.keyID, encryptionType: self.encryptionType) {
            let keyData = NSKeyedArchiver.archivedData(withRootObject: key)
            encryptionHandler.replacePersistentData(key.keyID, replacementData: keyData, encryptionType: self.encryptionType)
            return
        }
    }
    
    func findPublicKeyInBase64(_ key: PGPKeyWrapper)-> String{
        if let data = self.pgp.exportKeyWithoutArmor(key.key){
            return data
        }
        return ""
    }
    
    func addMailAddressesForKey(_ mailAddresses: [String], keyID: String){
        for addr in mailAddresses{
            let mailAddress = addr.lowercased()
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
    
    func removeMailAddressesForKey(_ mailAddresses: [String], keyID: String) {
        for addr in mailAddresses{
            let mailAddress = addr.lowercased()
            //remove keyID outof keyIDs
            if var keys = keyIDs[mailAddress]{
                if keys.contains(keyID) {
                    keys.remove(at: keys.index(of: keyID)!)
                    keyIDs[mailAddress] = keys
                }
            }
            //remove mailAddress outof addresses
            if var mAddresses = addresses[keyID]{
                if mAddresses.contains(mailAddress) {
                    mAddresses.remove(at: mAddresses.index(of: mailAddress)!)
                    addresses[keyID] = mAddresses
                }
            }
        }
        saveDictionarys()
    }
    
    func getKeyIDsForMailAddress(_ mailAddress: String) -> [String]?{
        return keyIDs[mailAddress]
    }
    
    func getActualKeyIDForMailaddress(_ mailaddress: String) -> String? {
        return keyIDs[mailaddress]?.last
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
    
    func getKey(_ keyID: String) -> PGPKeyWrapper? {
        if let data = (encryptionHandler.getPersistentData(keyID, encryptionType: self.encryptionType)) {
            let keywrapper = NSKeyedUnarchiver.unarchiveObject(with: data) as? PGPKeyWrapper
            return keywrapper
        }
        return nil
    }
    
    func getMailAddressesForKeyID(_ keyID: String) -> [String]?{
        return addresses[keyID]
    }
    
    func keyIDExists(_ keyID: String) -> Bool {
        if let addr = addresses[keyID] {
            return addr != []
        }
        return false
    }
    
    //if the actualPrivateKey is removed a old key is set as actualPrivateKey, if availiable
    func removeKey(_ keyID: String) {
        removePrivateKey(keyID)
        
        var addrs: [String] = []
        if let addrss = addresses[keyID] {
            addrs = addrss
        }
        self.removeMailAddressesForKey(addrs, keyID: keyID)
        encryptionHandler.deletePersistentData(keyID, encryptionType: self.encryptionType)
    }
    
    private func cleanIndex(_ keyID: String) {
        let index = keyID.components(separatedBy: "-")[0]+"-index"
        encryptionHandler.deletePersistentData(index, encryptionType: self.encryptionType)
    }
    
    //includes privatekeys too
    func removeAllKeys() {
        for keyID in privateKeys {
            self.encryptionHandler.deletePersistentData(keyID, encryptionType: self.encryptionType)
        }
        self.privateKeys = []
        self.actualPrivateKey = nil
        encryptionHandler.deletePersistentData("actualPrivateKey", encryptionType: self.encryptionType)
        encryptionHandler.deletePersistentData("privateKeys", encryptionType: self.encryptionType)
        let insertData = NSKeyedArchiver.archivedData(withRootObject: self.privateKeys)
        encryptionHandler.addPersistentData(insertData, searchKey: "privateKeys", encryptionType: self.encryptionType)
        for keyID in addresses.keys {
            self.removeKey(keyID)
            self.cleanIndex(keyID)
        }
        for keyID in privateKeys {
            self.removeKey(keyID)
            self.cleanIndex(keyID)
        }
        self.addresses = [:]
        self.keyIDs = [:]
        self.saveDictionarys()
    }
    
    func printAllKeyIDs() {
        print(self.addresses)
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
        var data = NSKeyedArchiver.archivedData(withRootObject: keyIDs as NSDictionary)
        encryptionHandler.replacePersistentData("keyIDs", replacementData: data, encryptionType: self.encryptionType)
        data = NSKeyedArchiver.archivedData(withRootObject: addresses as NSDictionary)
        encryptionHandler.replacePersistentData("addresses", replacementData: data, encryptionType: self.encryptionType)
    }
    
    private func addPrivateKey(_ key: PGPKeyWrapper) {
        if key.key.type == PGPKeyType.secret {
            privateKeys.append(key.keyID)
            var data = NSKeyedArchiver.archivedData(withRootObject: privateKeys)
            encryptionHandler.replacePersistentData("privateKeys", replacementData: data, encryptionType: self.encryptionType)
            actualPrivateKey = key.keyID
            data = NSKeyedArchiver.archivedData(withRootObject: actualPrivateKey!)
            if encryptionHandler.hasPersistentData("actualPrivateKey", encryptionType: self.encryptionType) {
                encryptionHandler.replacePersistentData("actualPrivateKey", replacementData: data, encryptionType: self.encryptionType)
            }
            else {
                encryptionHandler.addPersistentData(data, searchKey: "actualPrivateKey", encryptionType: self.encryptionType)
            }
            self.useOnlyActualPrivateKey()
        }
    }
    
    private func removePrivateKey(_ keyID: String) {
        if privateKeys.contains(keyID) {
            privateKeys.remove(at: privateKeys.index(of: keyID)!)
            actualPrivateKey = privateKeys.last
            if let key = actualPrivateKey {
                let data = NSKeyedArchiver.archivedData(withRootObject: key)
                encryptionHandler.replacePersistentData("actualPrivateKey", replacementData: data, encryptionType: self.encryptionType)
            }
            else {
                encryptionHandler.deletePersistentData("actualPrivateKey", encryptionType: self.encryptionType)
            }
            let data = NSKeyedArchiver.archivedData(withRootObject: privateKeys)
            encryptionHandler.addPersistentData(data, searchKey: "privateKeys", encryptionType: self.encryptionType)
            self.useOnlyActualPrivateKey()
        }
    }
}
