//
//  PGPEncryption.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 18.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

class PGPEncryption : Encryption {
    
    
    internal let encryptionHandler: EncryptionHandler
    internal let keyManager: PGPKeyManagement
    //internal let keyIDs : []
    
    var encryptionType: EncryptionType {
        get {
            return EncryptionType.PGP
        }
    }
    
    required init(encHandler: EncryptionHandler) {
        self.encryptionHandler = encHandler
        self.keyManager = PGPKeyManagement(encryptionHandler: self.encryptionHandler)
    }
    
    func isUsed(mail: Mail) -> Bool {
        if let plain = mail.body {
            return isUsed(plain, key: nil)
        }
        return false
    }
    
    //key is unused
    func isUsed(text: String, key: KeyWrapper?) -> Bool {
        return (text.hasPrefix("-----BEGIN PGP MESSAGE-----") && text.hasSuffix("-----END PGP MESSAGE-----")) || (text.hasPrefix("-----BEGIN PGP SIGNED MESSAGE-----") && text.hasSuffix("-----END PGP SIGNATURE-----"))
    }
    
    //check whether this encryption is used in this mail for encryption. nil is returned, if there is no answer to be made at the moment.
    func isUsedForEncryption(mail: Mail) -> Bool? {
        if let plain = mail.body {
            return isUsedForEncryption(plain, key: nil)
        }
        return false
    }
    
    //check whether this encryption is used in this text for encryption. the key is not known to be used. nil is returned, if there is no answer to be made at the moment.
    //key unused
    func isUsedForEncryption(text: String, key: KeyWrapper?) -> Bool?{
        return text.hasPrefix("-----BEGIN PGP MESSAGE-----") && text.hasSuffix("-----END PGP MESSAGE-----")
    }
    
    //check whether this encryption is used in this mail for signing. nil is returned, if there is no answer to be made at the moment.
    func isUsedForSignature(mail: Mail) -> Bool?{
        //TODO api-check
        //baut auf der Annahme auf, dass der signierte Teil nach dem entschlüsseln noch vorhanden ist.
        if let plain = mail.decryptedBody {
            return isUsedForSignature(plain, key: nil)
        }
        else if let plain = mail.body {
            return isUsedForSignature(plain, key: nil)
        }
        return false
    }
    
    //check whether this encryption is used in this text for signing. nil is returned, if there is no answer to be made at the moment.
    //key unused
    func isUsedForSignature(text: String, key: KeyWrapper?) -> Bool? {
        if !isUsedForEncryption(text, key: nil)! {
            return text.hasPrefix("-----BEGIN PGP SIGNED MESSAGE-----") && text.hasSuffix("-----END PGP SIGNATURE-----")
        }
        return nil
    }
    
    //TODO
    //decrypt the mails body. the decryted body will be saved in the mail object.
    func decrypt(mail: Mail){
        if self.isUsed(mail) {
            let bodyData = mail.body!.dataUsingEncoding(NSUTF8StringEncoding)!
            var data = try? keyManager.pgp.decryptData(bodyData, passphrase: nil)
            if data == nil {
                self.keyManager.useAllPrivateKeys()
                //TODO add oldKeyUsed attribute in Mail object
                data = try? keyManager.pgp.decryptData(mail.body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil)
                self.keyManager.useOnlyActualPrivateKey()
                if data != nil {
                    mail.decryptedWithOldPrivateKey = true
                }
            }
            if let unwrappedData = data {
                mail.decryptedBody = String(data: unwrappedData, encoding: NSUTF8StringEncoding)
            }
        }
        /*if self.isUsed(mail) {
            //sortInPlace auf keyRecords, um Reihnfolge für signature keys zu bekommen.
            var signed = false
            var valid = false
            var integrityProtected = false
            let verificationKey = keyManager.getKey(keyManager.)
            var data = try? keyManager.pgp.decryptData(mail.body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: )
            if data == nil {
                self.keyManager.useAllPrivateKeys()
                //TODO add oldKeyUsed attribute in Mail object
                data = try? keyManager.pgp.decryptData(mail.body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil)
                self.keyManager.useOnlyActualPrivateKey()
                if data != nil {
                    mail.oldKeyUsed = true
                }
            }
            if let unwrappedData = data {
                mail.decryptedBody = String(data: unwrappedData, encoding: NSUTF8StringEncoding)
            }
        }*/
    }
    
    func decryptAndSignatureCheck(mail: Mail) {
        if self.isUsed(mail) {
            let bodyData = mail.body!.dataUsingEncoding(NSUTF8StringEncoding)!
            var data = try? keyManager.pgp.decryptData(bodyData, passphrase: nil)
            if data == nil {
                self.keyManager.useAllPrivateKeys()
                //TODO add oldKeyUsed attribute in Mail object
                data = try? keyManager.pgp.decryptData(mail.body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil)
                self.keyManager.useOnlyActualPrivateKey()
                if data != nil {
                    mail.decryptedWithOldPrivateKey = true
                }
            }
            if let unwrappedData = data {
                mail.decryptedBody = String(data: unwrappedData, encoding: NSUTF8StringEncoding)
            }
        }
    }
    
    //decrypt the text with the given key and return it.
    func decrypt(text: String, keyID: String) -> String?{
        if let privKeys = keyManager.getAllPrivateKeyIDs() {
            if !privKeys.contains(keyID) {
                return nil
            }
        }
        if let key = keyManager.getKey(keyID) {
            let pgp = ObjectivePGP.init()
            pgp.keys.append(key.key)
            if let decr = try? pgp.decryptData(text.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil) {
                return String(data: decr, encoding: NSUTF8StringEncoding)
            }
        }
        return nil
    }
    
    //TODO
    //check whether the mail is correctly signed with this encryption. nil is returned, if there is no answer to be made at the moment.
    func isCorrectlySigned(mail: Mail) -> Bool?{
        return false
    }
    
    //TODO
    //check whether the text is correctly signed with this encryption.
    func isCorrectlySigned(text: String, key: KeyWrapper) -> Bool?{
        return false
    }
    
    //TODO
    //encrypt mail for contact
    func encrypt(mail: Mail){
        
    }
    
    //TODO
    //encrypt text with key
    func encrypt(text: String, keyIDs: [String]) -> NSData? {
        var encData : NSData? = nil
        var keys : [PGPKey] = []
        for id in keyIDs {
            if let key = keyManager.getKey(id) {
                keys.append(key.key)
            }
            else {
                print("PGPEncryption.encrypt: No key found for keyID "+id)
                return nil
            }
        }
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            encData = try? keyManager.pgp.encryptData(data, usingPublicKeys: keys, armored: true)
        }
        else {
            print("PGPEncryption.encrypt: text has to be in UTF8Encoding")
        }
        return encData
    }
    
    func encrypt(text: String, mailaddresses: [String]) -> NSData? {
        var keyIDs : [String] = []
        for addr in mailaddresses {
            if let ids = keyManager.getKeyIDsForMailAddress(addr) {
                if ids != [] {
                    keyIDs.append(ids.last!)
                }
                else {
                    print("PGPEncryption.encrypt: no keyID for mailaddress "+addr+" found")
                    return nil
                }
            }
            else {
                print("PGPEncryption.encrypt: no keyID for mailaddress "+addr+" found")
                return nil
            }
        }
        
        return encrypt(text, keyIDs: keyIDs)
    }
    
    //TODO
    //sign mail
    func sign(mail: Mail){
        
    }
    
    //TODO
    //sign text
    func sign(text: String, key: KeyWrapper) -> String{
        return ""
    }
    
    //TODO
    //sign and encrypt mail for contact
    func signAndEncrypt(mail: Mail, forContact: KeyRecord){
        
    }
    
    //TODO
    func signAndEncrypt(text: String, key: KeyWrapper) -> String {
        return ""
    }
    
    //chooses first key in data. others will be ignored
    func addKey(keyData: NSData, forMailAddress: String?) -> String? {
        var addrs : [String] = []
        if let addr = forMailAddress {
            addrs = [addr]
        }
        return self.addKey(keyData, forMailAddresses: addrs)
    }
    
    //chooses first key in data. others will be ignored
    func addKey(keyData: NSData, forMailAddresses: [String]?) -> String?{
        return self.addKey(keyData, forMailAddresses: forMailAddresses, discoveryMailUID: nil)
    }
    
    //chooses first key in data. others will be ignored
    func addKey(keyData: NSData, forMailAddresses: [String]?, discoveryMailUID: UInt64?) -> String? {
        if let tmpKey = self.keyManager.pgp.keysFromData(keyData) {
            var addrs : [String] = []
            if let addr = forMailAddresses {
                addrs = addr
            }
            let key = PGPKeyWrapper.init(key: tmpKey[0], mailAddresses: addrs, discoveryMailUID: discoveryMailUID, keyManager: self.keyManager)
            return key.keyID
        }
        return nil
    }
    
    //chooses first key in data. others will be ignored
    func addKey(keyData: NSData, discoveryMail: Mail?) -> String? {
        var discoveryMailUID: UInt64? = nil
        var forMailAddresses: [String]? = nil
        if let mail = discoveryMail {
            discoveryMailUID = mail.uid
            forMailAddresses = [mail.from.address]
        }
        return self.addKey(keyData, forMailAddresses: forMailAddresses, discoveryMailUID: discoveryMailUID)
    }
    
    //TODO maybe remove here. used in keyWrapper
    //forMailAddress has to be set (not nil)
    /*func addKey(key: PGPKeyWrapper, forMailAddress: String?, callBack: ((success: Bool) -> Void)?){
        /*if forMailAddress == nil {
            if let cb = callBack {
                cb(success: false)
            }
            return
        }
        self.keyManager.addKey(key, forMailAddresses: [forMailAddress!], callBack: nil)*/
        //überprüfen, ob key in dictionary der email zugeordnet
        
        if let cb = callBack {
            cb(success: false)
        }
        return
    }*/
    
    private func getMaxIndex(fingerprint: String) -> Int64 {
        var index : Int64 = 0
        if let indexData = encryptionHandler.getPersistentData(fingerprint+"-index", encryptionType: self.encryptionType){
            indexData.getBytes(&index, length: sizeof(Int64))
        }
        
        return index
    }
    
    //TODO
    func hasKey(enzContact: EnzevalosContact) -> Bool {
        return false
    }
    
    func hasKey(mailaddress: String) -> Bool {
        if let ids = keyManager.getKeyIDsForMailAddress(mailaddress) {
            return ids != []
        }
        return false
    }
    
    //TODO
    func getKeyIDs(enzContact: EnzevalosContact) -> [String]? {
        return nil
    }
    
    func getKeyIDs(mailaddress: String) -> [String]?{
        return keyManager.getKeyIDsForMailAddress(mailaddress)
    }
    
    func getKey(keyID: String) -> KeyWrapper? {
        return self.keyManager.getKey(keyID)
    }
    
    
    /*func updateKey(key: PGPKeyWrapper, callBack: ((success: Bool) -> Void)?) {
        
    }*/
    
    func removeKey(keyID: String){
        self.keyManager.removeKey(keyID)
    }
    
    func removeKey(key: KeyWrapper) {
        self.removeKey(key.keyID)
    }
    
    func addMailAddressForKey(mailAddress: String, keyID: String) {
        self.addMailAddressesForKey([mailAddress], keyID: keyID)
    }
    
    func addMailAddressesForKey(mailAddresses: [String], keyID: String) {
        self.keyManager.addMailAddressesForKey(mailAddresses, keyID: keyID)
    }
    
    func removeMailAddressForKey(mailaddress: String, keyID: String){
        self.removeMailAddressesForKey([mailaddress], keyID: keyID)
    }
    
    func removeMailAddressesForKey(mailaddresses: [String], keyID: String){
        self.keyManager.removeMailAddressesForKey(mailaddresses, keyID: keyID)
    }
    
    func keyIDExists(keyID: String) -> Bool {
        return self.keyManager.keyIDExists(keyID)
    }
    
    //TODO
    func keyOfThisEncryption(keyData: NSData) -> Bool? {
        return nil
    }
    
    
}
