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
    
    static func hasKey(enzContact: EnzevalosContact) -> Bool {
        for (_, enc) in encryptions {
            if enc.hasKey(enzContact) {
                return true
            }
        }
        return false
    }
    
    static func getEncryptionTypeForMail(mail: Mail) -> EncryptionType {
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
    
    func hasPersistentData(searchKey: String, encryptionType: EncryptionType) -> Bool {
        return getPersistentData(searchKey, encryptionType: encryptionType) != nil
    }
    
    //handle entrys in keychain for different Encryptions
    func addPersistentData(data: NSData, searchKey: String, encryptionType: EncryptionType) {
        if (try? keychain.getData(encryptionType.rawValue+"-"+searchKey)) != nil {
            return
        }
        keychain[data: encryptionType.rawValue+"-"+searchKey] = data
    }
    
    //for all encryptions
    /*func getPersistentData(searchKey: String) -> NSData? {
        
    }*/
    
    //for given encryption
    func getPersistentData(searchKey: String, encryptionType: EncryptionType) -> NSData? {
        return (try! keychain.getData(encryptionType.rawValue+"-"+searchKey))
    }
    
    func replacePersistentData(searchKey: String, replacementData: NSData, encryptionType: EncryptionType) {
        if (try? keychain.getData(encryptionType.rawValue+"-"+searchKey)) == nil {
            return
        }
        keychain[data: encryptionType.rawValue+"-"+searchKey] = replacementData
    }
    
    func deletePersistentData(searchKey: String, encryptionType: EncryptionType) {
        if (try? keychain.getData(encryptionType.rawValue+"-"+searchKey)) == nil {
            return
        }
        keychain[data: encryptionType.rawValue+"-"+searchKey] = nil
    }
}
