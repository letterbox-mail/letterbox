//
//  Encryption.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 11.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

public protocol Encryption {
    
    /**
     * ATTENTION: always have a look at the concrete Encryption you are working with! It my differ in some cases from this definition. e.g. some parameters may be used or unused.
     * In some functions nil is returned, if there is no answer to be made at the moment. An example for this case is the PGPEncryption. You have to decrypt the message before you can see, if there is a signature
     */
    
    var encryptionHandler: EncryptionHandler {get}
    var encryptionType: EncryptionType {get}
    
    init(encHandler: EncryptionHandler)
    
    //check whether this encryption is used in this mail. This means is it used for encryption OR signing.
    func isUsed(mail: Mail) -> Bool
    
    //check whether this encryption is used in this text. This means is it used for encryption OR signing. the key is not known to be used. nil is returned, if there is no answer to be made at the moment.
    func isUsed(text: String, key: KeyWrapper?) -> Bool
    
    //check whether this encryption is used in this mail for encryption. nil is returned, if there is no answer to be made at the moment.
    func isUsedForEncryption(mail: Mail) -> Bool?
    
    //check whether this encryption is used in this text for encryption. the key is not known to be used. nil is returned, if there is no answer to be made at the moment.
    func isUsedForEncryption(text: String, key: KeyWrapper?) -> Bool?
    
    //check whether this encryption is used in this mail for signing. nil is returned, if there is no answer to be made at the moment.
    func isUsedForSignature(mail: Mail) -> Bool?
    
    //check whether this encryption is used in this text for signing. nil is returned, if there is no answer to be made at the moment.
    func isUsedForSignature(text: String, key: KeyWrapper?) -> Bool?
    
    //decrypt the mails body. the decryted body will be saved in the mail object.
    func decrypt(mail: Mail) -> String?
    
    //decrypt the mails body. the decryted body will be saved in the mail object.
    //Signaturechecking included. will be set in mail object too.
    func decryptAndSignatureCheck(mail: Mail)
    
    //decrypt the text with the given key and return it.
    func decrypt(text: String, keyID: String) -> String?
    
    //check whether the mail is correctly signed with this encryption. nil is returned, if there is no answer to be made at the moment.
    func isCorrectlySigned(mail: Mail) -> Bool?
    
    //check whether the text is correctly signed with this encryption.
    func isCorrectlySigned(text: String, key: KeyWrapper) -> Bool?
    
    //encrypt mail for contact
    func encrypt(mail: Mail)
    
    func encrypt(text: String, mailaddresses: [String]) -> NSData?
    
    //encrypt text with key
    func encrypt(text: String, keyIDs: [String]) -> NSData?
    
    //sign mail
    func sign(mail: Mail)
    
    //sign text
    func sign(text: String, key: KeyWrapper) -> String
    
    //sign and encrypt mail for contact
    func signAndEncrypt(mail: Mail, forContact: KeyRecord)
    func signAndEncrypt(text: String, keyIDs: [String]) -> NSData?
    func signAndEncrypt(text: String, mailaddresses: [String]) -> NSData?
    
    func addKey(keyData: NSData, forMailAddresses: [String]?) -> String?
    
    func addKey(keyData: NSData, forMailAddresses: [String]?, discoveryMailUID: UInt64?) -> String?
    
    //key is connected to the senders address, if discoveryMail is set
    func addKey(keyData: NSData, discoveryMail: Mail?) -> String?
    
    //will be maybe deleted... because keyWrapper will be added when constructed
    //func addKey(key: KeyWrapper, forMailAddress: [String]?, callBack: ((success: Bool) -> Void)?)
    
    func hasKey(enzContact: EnzevalosContact) -> Bool
    func hasKey(mailaddress: String) -> Bool
    func getKeyIDs(enzContact: EnzevalosContact) -> [String]?
    func getKeyIDs(mailaddress: String) -> [String]?
    
    func getActualKeyID(mailaddress: String) -> String?
    
    func keyIDExists(keyID: String) -> Bool
    
    func getKey(keyID: String) -> KeyWrapper?
    
    //internaly done; update is done when a keyWrapper is manipulated
    //func updateKey(key: KeyWrapper, callBack: ((success: Bool) -> Void)?)
    func removeKey(keyID: String) //-> Bool
    
    func removeKey(key: KeyWrapper) //-> Bool
    
    //includes privatekeys too
    func removeAllKeys()
    
    func addMailAddressForKey(mailAddress: String, keyID: String)
    
    func removeMailAddressForKey(mailaddress: String, keyID: String)
    
    func keyOfThisEncryption(keyData: NSData) -> Bool?
}
