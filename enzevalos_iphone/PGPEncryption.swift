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
    
    func getPGPKeyManagement() -> PGPKeyManagement {
        return keyManager
    }
    
    func isUsed(_ mail: PersistentMail) -> Bool {
        if let plain = mail.body {
            return isUsed(plain, key: nil)
        }
        return false
    }
    
    //key is unused
    func isUsed(_ text: String, key: KeyWrapper?) -> Bool {
        if let usedForSignature = self.isUsedForSignature(text, key: key), usedForSignature {
            return true
        }
        return self.isUsedForEncryption(text, key: key)!
    }
    
    //check whether this encryption is used in this mail for encryption. nil is returned, if there is no answer to be made at the moment.
    func isUsedForEncryption(_ mail: PersistentMail) -> Bool? {
        if let plain = mail.body {
            return isUsedForEncryption(plain, key: nil)
        }
        return false
    }
    
    //check whether this encryption is used in this text for encryption. the key is not known to be used. nil is returned, if there is no answer to be made at the moment.
    //key unused
    func isUsedForEncryption(_ text: String, key: KeyWrapper?) -> Bool?{
        return text.hasPrefix("-----BEGIN PGP MESSAGE-----") && (text.hasSuffix("-----END PGP MESSAGE-----\n") || text.hasSuffix("-----END PGP MESSAGE-----"))
    }
    
    //check whether this encryption is used in this mail for signing. nil is returned, if there is no answer to be made at the moment.
    func isUsedForSignature(_ mail: PersistentMail) -> Bool?{
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
    func isUsedForSignature(_ text: String, key: KeyWrapper?) -> Bool? {
        if !isUsedForEncryption(text, key: nil)! {
            return text.hasPrefix("-----BEGIN PGP SIGNED MESSAGE-----") && (text.hasSuffix("-----END PGP SIGNATURE-----\n") || text.hasSuffix("-----END PGP SIGNATURE-----"))
        }
        return nil
    }
    
    
    func decryptMime(_ data: Data) -> Data?{
        let s = String.init(data: data, encoding: String.Encoding.utf8)
        if s != nil  && self.isUsed(s!, key: nil) {
                var plain = try? keyManager.pgp.decryptData(data, passphrase: nil)
                if plain == nil {
                    self.keyManager.useAllPrivateKeys()
                    //TODO add oldKeyUsed attribute in Mail object
                    plain = try? keyManager.pgp.decryptData(data, passphrase: nil)
                    self.keyManager.useOnlyActualPrivateKey()
                }
                return plain
            }
        return nil
    }
    
    func decryptedMime(_ data: Data, from: String) -> DecryptedData?{
        var sigState: SignatureState = SignatureState.NoSignature
        var encState: EncryptionState = EncryptionState.NoEncryption
        var handeledData: Data?
        var signkey: String?
        
        if true {
            //has to be var because it is given as pointer to obj-c-code
            var error: NSErrorPointer = NSErrorPointer.none
            var temp = keyManager.pgp.decryptDataFirstPart(data, passphrase: nil, integrityProtected: nil, error: error)
            var maybeUsedKeys: [String] = []
            //has to be var because it is given as pointer to obj-c-code
            var signed = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
            signed[0] = false
            //has to be var because it is given as pointer to obj-c-code
            var valid = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
            valid[0] = false
            //print(temp.incompleteKeyID,"  ",temp.onePassSignaturePacket)
            handeledData = temp.plaintextData
            if handeledData != nil{
                encState = EncryptionState.ValidedEncryptedWithActualKey
            }
            else {
                self.keyManager.useAllPrivateKeys()
                temp = keyManager.pgp.decryptDataFirstPart(data, passphrase: nil, integrityProtected: nil, error: error)
                handeledData = temp.plaintextData //TODO Does this works?
                self.keyManager.useOnlyActualPrivateKey()
                if handeledData != nil {
                    encState = EncryptionState.ValidEncryptedWithOldKey
                }
            }
            if error.debugDescription == "MDC validation failed" {
                encState = EncryptionState.UnableToDecrypt
            }
            if let unwrappedData = handeledData {
                handeledData = unwrappedData
                if let allKeyIDs = self.keyManager.getKeyIDsForMailAddress(from), let theirKeyID = temp.incompleteKeyID {
                    maybeUsedKeys = self.getLibaryKeyIDOverlap(theirKeyID, ourKeyIDs: allKeyIDs)
                }
                for maybeUsedKey in maybeUsedKeys {
                    if let key = self.keyManager.getKey(maybeUsedKey) {
                        //FIXME
                        let done : ObjCBool
                        done = (self.keyManager.pgp.decryptDataSecondPart(temp, verifyWithPublicKey: key.key, signed: signed, valid: valid, error: error)[0])
                        if let errorHappening = (error?.debugDescription.contains("Missing")), errorHappening {
                            sigState = SignatureState.InvalidSignature
                            break
                        }
                        
                        if !done.boolValue {
                            sigState = SignatureState.NoSignature
                            break
                        }
                        if valid.pointee.boolValue{
                            sigState = SignatureState.ValidSignature
                            signkey = key.keyID
                            break
                        }
                        else{
                            sigState = SignatureState.InvalidSignature
                            break
                        }
                    }
                }
                return  DecryptedData.init(decryptedBody: handeledData, sigState: sigState, encState: encState, key: signkey, encType: EncryptionType.PGP)
            }
        }
        encState = EncryptionState.UnableToDecrypt
        
        return DecryptedData.init(decryptedBody: handeledData, sigState: sigState, encState: encState, key: signkey, encType: EncryptionType.PGP)
    
    }
    
    
    
    
    //TODO
    //decrypt the mails body. the decryted body will be saved in the mail object.
    func decrypt(_ mail: PersistentMail)-> String?{
        if self.isUsed(mail) {
            let bodyData = mail.body!.data(using: String.Encoding.utf8)!
            var data = try? keyManager.pgp.decryptData(bodyData, passphrase: nil)
            if data == nil {
                self.keyManager.useAllPrivateKeys()
                //TODO add oldKeyUsed attribute in Mail object
                data = try? keyManager.pgp.decryptData(mail.body!.data(using: String.Encoding.utf8)!, passphrase: nil)
                self.keyManager.useOnlyActualPrivateKey()
                if data != nil {
                    mail.decryptedWithOldPrivateKey = true
                }
            }
            if let unwrappedData = data {
                mail.decryptedBody = String(data: unwrappedData, encoding: String.Encoding.utf8)
                return String(data: unwrappedData, encoding: String.Encoding.utf8)
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
        return nil
    }
    
    func decryptAndSignatureCheck(_ mail: PersistentMail) {
        if self.isUsed(mail) {
            let bodyData = mail.body!.data(using: String.Encoding.utf8)!
            var data: Data?
            //has to be var because it is given as pointer to obj-c-code
            var error: NSErrorPointer = NSErrorPointer.none
            var temp = keyManager.pgp.decryptDataFirstPart(bodyData, passphrase: nil, integrityProtected: nil, error: error)
            var maybeUsedKeys: [String] = []
            //has to be var because it is given as pointer to obj-c-code
            var signed = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
            signed[0] = false
            //has to be var because it is given as pointer to obj-c-code
            var valid = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
            valid[0] = false
            //print(temp.incompleteKeyID,"  ",temp.onePassSignaturePacket)
                data = temp.plaintextData
                if data == nil {
                    self.keyManager.useAllPrivateKeys()
                    temp = keyManager.pgp.decryptDataFirstPart(bodyData, passphrase: nil, integrityProtected: nil, error: error)
                    data = temp.plaintextData
                    self.keyManager.useOnlyActualPrivateKey()
                    if data != nil {
                        mail.decryptedWithOldPrivateKey = true
                    }
                }
            if error.debugDescription == "MDC validation failed" {
                mail.trouble = true
            }
                if let unwrappedData = data {
                    mail.decryptedBody = String(data: unwrappedData, encoding: String.Encoding.utf8)
                    if let allKeyIDs = self.keyManager.getKeyIDsForMailAddress(mail.from.mailAddress), let theirKeyID = temp.incompleteKeyID {
                        maybeUsedKeys = self.getLibaryKeyIDOverlap(theirKeyID, ourKeyIDs: allKeyIDs)
                    }
                    for maybeUsedKey in maybeUsedKeys {
                        if let key = self.keyManager.getKey(maybeUsedKey) {
                            //FIXME
                            let done : ObjCBool
                            done = (self.keyManager.pgp.decryptDataSecondPart(temp, verifyWithPublicKey: key.key, signed: signed, valid: valid, error: error)[0])
                            if let errorHappening = (error?.debugDescription.contains("Missing")), errorHappening {
                                mail.trouble = true
                                mail.isCorrectlySigned = false
                                break
                            }

                            if !done.boolValue {
                                mail.isSigned = false
                                mail.isCorrectlySigned = false
                                break
                            }
                            mail.isSigned = signed.pointee.boolValue
                            mail.isCorrectlySigned = valid.pointee.boolValue
                            if mail.isSigned && mail.isCorrectlySigned {
                                mail.keyID = key.keyID
                                break
                            }
                        }
                    }
                    if mail.isSigned && !mail.isCorrectlySigned && maybeUsedKeys != [] {
                        mail.trouble = true
                    }
                    return
                }
        }
        mail.unableToDecrypt = true
    }
    
    //decrypt the text with the given key and return it.
    func decrypt(_ text: String, keyID: String) -> String?{
        if let privKeys = keyManager.getAllPrivateKeyIDs() {
            if !privKeys.contains(keyID) {
                return nil
            }
        }
        if let key = keyManager.getKey(keyID) {
            let pgp = ObjectivePGP.init()
            pgp.keys.append(key.key)
            if let decr = try? pgp.decryptData(text.data(using: String.Encoding.utf8)!, passphrase: nil) {
                return String(data: decr, encoding: String.Encoding.utf8)
            }
        }
        return nil
    }
    
    //TODO
    //check whether the mail is correctly signed with this encryption. nil is returned, if there is no answer to be made at the moment.
    func isCorrectlySigned(_ mail: PersistentMail) -> Bool?{
        return false
    }
    
    //TODO
    //check whether the text is correctly signed with this encryption.
    func isCorrectlySigned(_ text: String, key: KeyWrapper) -> Bool?{
        return false
    }
    
    //TODO
    //encrypt mail for contact
    func encrypt(_ mail: PersistentMail){
        
    }
    
    //encrypt text with key
    func encrypt(_ text: String, keyIDs: [String]) -> Data? {
        var encData : Data? = nil
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
        if let data = text.data(using: String.Encoding.utf8) {
            encData = try? keyManager.pgp.encryptData(data, usingPublicKeys: keys, armored: true)
        }
        else {
            print("PGPEncryption.encrypt: text has to be in UTF8Encoding")
        }
        return encData
    }
    
    func encrypt(_ text: String, mailaddresses: [String]) -> Data? {
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
    func sign(_ mail: PersistentMail){
        
    }
    
    //TODO
    //sign text
    func sign(_ text: String, key: KeyWrapper) -> String{
        return ""
    }
    
    //TODO
    //sign and encrypt mail for contact
    func signAndEncrypt(_ mail: PersistentMail, forContact: KeyRecord){
        
    }
    
    func signAndEncrypt(_ text: String, keyIDs: [String]) -> Data? {
        var encData : Data? = nil
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
        if let data = text.data(using: String.Encoding.utf8) {
            if let myKeyID = keyManager.getPrivateKeyID() {
                if let myKey = keyManager.getKey(myKeyID) {
                    encData = try? keyManager.pgp.encryptData(data, usingPublicKeys: keys, signWithSecretKey: myKey.key, passphrase: "", armored: true)
                }
                else {
                    return nil
                }
            }
            else {
                return nil
            }
        }
        else {
            print("PGPEncryption.encrypt: text has to be in UTF8Encoding")
        }
        return encData
    }
    
    func signAndEncrypt(_ text: String, mailaddresses: [String]) -> Data? {
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
        
        return signAndEncrypt(text, keyIDs: keyIDs)
    }
    
    //chooses first key in data. others will be ignored
    func addKey(_ keyData: Data, forMailAddress: String?) -> String? {
        var addrs : [String] = []
        if let addr = forMailAddress {
            addrs = [addr]
        }
        return self.addKey(keyData, forMailAddresses: addrs)
    }
    
    //chooses first key in data. others will be ignored
    func addKey(_ keyData: Data, forMailAddresses: [String]?) -> String?{
        return self.addKey(keyData, forMailAddresses: forMailAddresses, discoveryMailUID: nil)
    }
    
    //chooses first key in data. others will be ignored
    func addKey(_ keyData: Data, forMailAddresses: [String]?, discoveryMailUID: UInt64?) -> String? {
        if let tmpKey = self.keyManager.pgp.keys(from: keyData) {
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
    func addKey(_ keyData: Data, discoveryMail: PersistentMail?) -> String? {
        var discoveryMailUID: UInt64? = nil
        var forMailAddresses: [String]? = nil
        if let mail = discoveryMail {
            discoveryMailUID = mail.uid
            forMailAddresses = [mail.from.mailAddress]
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
    
    fileprivate func getMaxIndex(_ fingerprint: String) -> Int64 {
        var index : Int64 = 0
        if let indexData = encryptionHandler.getPersistentData(fingerprint+"-index", encryptionType: self.encryptionType){
            (indexData as NSData).getBytes(&index, length: MemoryLayout<Int64>.size)
        }
        
        return index
    }
    
    func hasKey(_ enzContact: EnzevalosContact) -> Bool {
        if let addrs = enzContact.addresses {
            if let mailaddrs : [Mail_Address] = (addrs.allObjects as? [Mail_Address]) {
                for mail in mailaddrs {
                    if self.hasKey(mail.address) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func hasKey(_ mailaddress: String) -> Bool {
        if let ids = keyManager.getKeyIDsForMailAddress(mailaddress) {
            return ids != []
        }
        return false
    }
    
    //TODO
    func getKeyIDs(_ enzContact: EnzevalosContact) -> [String]? {
        return nil
    }
    
    func getKeyIDs(_ mailaddress: String) -> [String]?{
        return keyManager.getKeyIDsForMailAddress(mailaddress)
    }
    
    func getActualKeyID(_ mailaddress: String) -> String? {
        return self.keyManager.getActualKeyIDForMailaddress(mailaddress)
    }
    
    
    func getKey(_ keyID: String) -> KeyWrapper? {
        return self.keyManager.getKey(keyID)
    }
    
    
    /*func updateKey(key: PGPKeyWrapper, callBack: ((success: Bool) -> Void)?) {
        
    }*/
    
    func removeKey(_ keyID: String){
        self.keyManager.removeKey(keyID)
    }
    
    func removeKey(_ key: KeyWrapper) {
        self.removeKey(key.keyID)
    }
    
    //includes privatekeys too
    func removeAllKeys() {
        self.keyManager.removeAllKeys()
    }
    
    func printAllKeyIDs() {
        keyManager.printAllKeyIDs()
    }
    
    func addMailAddressForKey(_ mailAddress: String, keyID: String) {
        self.addMailAddressesForKey([mailAddress], keyID: keyID)
    }
    
    func addMailAddressesForKey(_ mailAddresses: [String], keyID: String) {
        self.keyManager.addMailAddressesForKey(mailAddresses, keyID: keyID)
    }
    
    func removeMailAddressForKey(_ mailaddress: String, keyID: String){
        self.removeMailAddressesForKey([mailaddress], keyID: keyID)
    }
    
    func removeMailAddressesForKey(_ mailaddresses: [String], keyID: String){
        self.keyManager.removeMailAddressesForKey(mailaddresses, keyID: keyID)
    }
    
    func keyIDExists(_ keyID: String) -> Bool {
        return self.keyManager.keyIDExists(keyID)
    }
    
    //TODO
    func keyOfThisEncryption(_ keyData: Data) -> Bool? {
        return nil
    }
    
    func autocryptHeader(_ adr: String) -> String? {
        if let keyId = self.getActualKeyID(adr){
            let key = self.getKey(keyId) as! PGPKeyWrapper
            let pgpManger = self.keyManager
            var string = "adr = " + adr + "; type = 1;"
            let enc = UserManager.loadUserValue(Attribute.prefEncryption) as! Bool
            if enc{
                string = string + "prefer-encrypted = mutal"
            }
            string = string + ";key = "
            if let keyBase64 = pgpManger.pgp.exportKeyWithoutArmor(key.key){
                string = string + keyBase64
            }
            return string
        }
        return nil
    }
    
    
    //the libary (ObjectivePGP) we use has a different definition of keyID than we have. their keyID is calculated outof the key. We take their keyID and add a index in the end to handle collisions
    private func getLibaryKeyIDOverlap(_ libaryKeyID: String, ourKeyIDs: [String]) -> [String] {
        var returnValue: [String] = []
        for ourKeyID in ourKeyIDs {
            if ourKeyID.hasPrefix(libaryKeyID) {
                returnValue.append(ourKeyID)
            }
        }
        return returnValue
    }
    
}
