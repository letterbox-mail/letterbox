//
//  PGPEncryption.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 18.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

class PGPEncryption : Encryption {
    
    
    internal let encryptionHandler: EncryptionHandler
    
    var encryptionType: EncryptionType {
        get {
            return EncryptionType.PGP
        }
    }
    
    required init(encHandler: EncryptionHandler) {
        self.encryptionHandler = encHandler
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
    
    //decrypt the mails body. the decryted body will be saved in the mail object.
    func decrypt(mail: Mail){
        
    }
    
    //decrypt the text with the given key and return it.
    func decrypt(text: String, key: KeyWrapper) -> String{
        
    }
    
    //check whether the mail is correctly signed with this encryption. nil is returned, if there is no answer to be made at the moment.
    func isCorrectlySigned(mail: Mail) -> Bool?{
        
    }
    
    //check whether the text is correctly signed with this encryption.
    func isCorrectlySigned(text: String, key: KeyWrapper) -> Bool?{
        
    }
    
    //encrypt mail for contact
    func encrypt(mail: Mail, forContact: KeyRecord?){
        
    }
    
    //encrypt text with key
    func encrypt(text: String, key: KeyWrapper) -> String{
        
    }
    
    //sign mail
    func sign(mail: Mail){
        
    }
    
    //sign text
    func sign(text: String, key: KeyWrapper) -> String{
        
    }
    
    //sign and encrypt mail for contact
    func signAndEncrypt(mail: Mail, forContact: KeyRecord){
        
    }
    
    func signAndEncrypt(text: String, key: KeyWrapper) -> String
    
    func addKey(keyData: NSData, forContact: KeyRecord?, callBack: ((success: Bool) -> Void)?)
    func addKey(key: KeyWrapper, forContact: KeyRecord?, callBack: ((success: Bool) -> Void)?)
    func hasKey(enzContact: EnzevalosContact) -> Bool
    func getKeyIDs(enzContact: EnzevalosContact) -> [Int64]?
    func getKey(keyID: Int64) -> KeyWrapper?
    func removeKey(key: KeyWrapper, keyRecord: KeyRecord, callBack: ((success: Bool) -> Void)?)
    
    
    
    func keyOfThisEncryption(keyData: NSData) -> Bool
    
    
}
