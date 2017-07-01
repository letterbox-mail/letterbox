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
    
    
    func generateKey(adr: String) -> KeyWrapper?
    
    //check whether this encryption is used in this mail. This means is it used for encryption OR signing.
    func isUsed(_ mail: PersistentMail) -> Bool
    
    //check whether this encryption is used in this text. This means is it used for encryption OR signing. the key is not known to be used. nil is returned, if there is no answer to be made at the moment.
    func isUsed(_ text: String, key: KeyWrapper?) -> Bool
    
    //check whether this encryption is used in this mail for encryption. nil is returned, if there is no answer to be made at the moment.
    func isUsedForEncryption(_ mail: PersistentMail) -> Bool?
    
    //check whether this encryption is used in this text for encryption. the key is not known to be used. nil is returned, if there is no answer to be made at the moment.
    func isUsedForEncryption(_ text: String, key: KeyWrapper?) -> Bool?
    
    //check whether this encryption is used in this mail for signing. nil is returned, if there is no answer to be made at the moment.
    func isUsedForSignature(_ mail: PersistentMail) -> Bool?
    
    //check whether this encryption is used in this text for signing. nil is returned, if there is no answer to be made at the moment.
    func isUsedForSignature(_ text: String, key: KeyWrapper?) -> Bool?
    
    //decrypt the mails body. the decryted body will be saved in the mail object.
    func decrypt(_ mail: PersistentMail) -> String?
    
    // decrypt the mime data. OLIVER TODO
   // func decryptMime(_ data: Data)-> Data?
    
    func decryptedMime(_ data: Data, from: String) -> DecryptedData?
    
    //decrypt the mails body. the decryted body will be saved in the mail object.
    //Signaturechecking included. will be set in mail object too.
    func decryptAndSignatureCheck(_ mail: PersistentMail)
    
    //decrypt the text with the given key and return it.
    func decrypt(_ text: String, keyID: String) -> String?
    
    //check whether the mail is correctly signed with this encryption. nil is returned, if there is no answer to be made at the moment.
    func isCorrectlySigned(_ mail: PersistentMail) -> Bool?
    
    //check whether the text is correctly signed with this encryption.
    func isCorrectlySigned(_ text: String, key: KeyWrapper) -> Bool?
    
    //encrypt mail for contact
    func encrypt(_ mail: PersistentMail)
    
    func encrypt(_ text: String, mailaddresses: [String]) -> Data?
    
    //encrypt text with key
    func encrypt(_ text: String, keyIDs: [String]) -> Data?
    
    //sign mail
    func sign(_ mail: PersistentMail)
    
    //sign text
    func sign(_ text: String, key: KeyWrapper) -> String
    
    //sign and encrypt mail for contact
    func signAndEncrypt(_ mail: PersistentMail, forContact: KeyRecord)
    func signAndEncrypt(_ text: String, keyIDs: [String]) -> Data?
    func signAndEncrypt(_ text: String, mailaddresses: [String]) -> Data?
    
    @discardableResult func addKey(_ keyData: Data, forMailAddresses: [String]?) -> String?
    
    @discardableResult func addKey(_ keyData: Data, forMailAddresses: [String]?, discoveryMailUID: UInt64?) -> String?
    
    //key is connected to the senders address, if discoveryMail is set
    @discardableResult func addKey(_ keyData: Data, discoveryMail: PersistentMail?) -> String?
    
    //will be maybe deleted... because keyWrapper will be added when constructed
    //func addKey(key: KeyWrapper, forMailAddress: [String]?, callBack: ((success: Bool) -> Void)?)
    
    func hasKey(_ enzContact: EnzevalosContact) -> Bool
    func hasKey(_ mailaddress: String) -> Bool
    func getKeyIDs(_ enzContact: EnzevalosContact) -> [String]?
    func getKeyIDs(_ mailaddress: String) -> [String]?
    
    func getActualKeyID(_ mailaddress: String) -> String?
    
    func keyIDExists(_ keyID: String) -> Bool
    
    func getKey(_ keyID: String) -> KeyWrapper?
    
    //internaly done; update is done when a keyWrapper is manipulated
    //func updateKey(key: KeyWrapper, callBack: ((success: Bool) -> Void)?)
    func removeKey(_ keyID: String) //-> Bool
    
    func removeKey(_ key: KeyWrapper) //-> Bool
    
    //includes privatekeys too
    func removeAllKeys()
    
    func printAllKeyIDs()
    
    func addMailAddressForKey(_ mailAddress: String, keyID: String)
    
    func removeMailAddressForKey(_ mailaddress: String, keyID: String)
    
    func keyOfThisEncryption(_ keyData: Data) -> Bool?
    
    func autocryptHeader(_ adr: String) -> String?
}
