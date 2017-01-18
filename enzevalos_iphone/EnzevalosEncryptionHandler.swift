//
//  EnzevalosEncryptionHandler.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 13.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//


import KeychainAccess

//statisch von außen drauf zugreifen; auf Objekt von Encryption aus zugreifen.
class EnzevalosEncryptionHandler : EncryptionHandler {
    private static let handler = EnzevalosEncryptionHandler()
    private static var encryptions : [EncryptionType : Encryption] = [
        EncryptionType.PGP : PGPEncryption(encHandler: handler)
        //TODO insert new Encryptions here
    ]
    
    static func getEncryption(encryptionType: EncryptionType) -> Encryption? {
        if encryptionType == EncryptionType.PGP {
            if encryptions[EncryptionType.PGP] == nil {
                encryptions[EncryptionType.PGP] = PGPEncryption(encHandler: handler)
            }
            return encryptions[EncryptionType.PGP]!
        }
        //TODO insert new Encryptions here
        return nil
    }
    
    static func getEncryptionForMail(mail: Mail) -> EncryptionType {
        for (type, enc) in encryptions {
            if enc.isUsed(mail) {
                return type
            }
        }
        return EncryptionType.unknown
    }
    
    //-----------------------------------------------------------------------------------------
    
    private var keychain : Keychain
    
    
    private init(){
        keychain = Keychain(service: "Enzevalos").accessibility(.WhenUnlocked)
    }
    
    //handle entrys in keychain for different Encryptions
    func addPersistentData(data: NSData, searchKey: String, encryptionType: EncryptionType, callBack: ((success: Bool) -> Void)?) {
        if (try? keychain.getData(encryptionType.rawValue+"-"+searchKey)) != nil {
            if let cb = callBack{
                cb(success: false)
            }
            return
        }
        //keychain[data: ] = data
    }
    
    //for all encryptions
    func getPersistentData(searchKey: String) -> NSData? {
        
    }
    
    //for given encryption
    func getPersistentData(searchKey: String, encryptionType: EncryptionType) -> NSData? {
        
    }
    
    func replacePersistentData(searchKey: String, replacementData: NSData, encryptionType: EncryptionType, callBack: ((success: Bool) -> Void)?) {
        
    }
    
    func deletePersistentData(searchKey: String, encryptionType: EncryptionType, callBack: ((success: Bool) -> Void)?) {
        
    }
}
