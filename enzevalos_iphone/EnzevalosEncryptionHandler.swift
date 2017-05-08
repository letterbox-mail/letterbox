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
    private static var encryptions: [EncryptionType: Encryption] = [
        EncryptionType.PGP: PGPEncryption(encHandler: handler)
        //TODO insert new Encryptions here
    ]
    
    static func getEncryption(_ encryptionType: EncryptionType) -> Encryption? {
        if encryptionType == EncryptionType.PGP {
            if encryptions[EncryptionType.PGP] == nil {
                encryptions[EncryptionType.PGP] = PGPEncryption(encHandler: handler)
            }
            return encryptions[EncryptionType.PGP]!
        }
        //TODO insert new Encryptions here
        return nil
    }
    
    static func hasKey(_ enzContact: EnzevalosContact) -> Bool {
        for (_, enc) in encryptions {
            if enc.hasKey(enzContact) {
                return true
            }
        }
        return false
    }
    
    static func hasKey(_ mailAddress: String) -> Bool {
        for (_, enc) in encryptions {
            if enc.hasKey(mailAddress) {
                return true
            }
        }
        return false
    }
    
    static func getEncryptionType(_ mailAddress: String) -> EncryptionType {
        for (_, enc) in encryptions {
            if enc.hasKey(mailAddress){
                return enc.encryptionType
            }
        }
        return EncryptionType.unknown
    }
    
    
    
    static func getEncryptionTypeForMail(_ mail: Mail) -> EncryptionType {
        for (type, enc) in encryptions {
            if enc.isUsed(mail) {
                return type
            }
        }
        return EncryptionType.unknown
    }
    
    //a mailaddress can be found in multiple encryptionTypes
    static func sortMailaddressesByEncryption(_ mailaddresses: [String]) -> [EncryptionType: [String]] {
        //TODO add different Encryptions here. This may be done via an attribute Mail_Address, setting the preffered encryption
        var returnValue : [EncryptionType : [String]] = [:]
        var inserted : Bool
        for addr in mailaddresses {
            inserted = false
            for (_, enc) in encryptions {
                if let array = enc.getKeyIDs(addr) {
                    if array != [] {
                        if returnValue[enc.encryptionType] == nil {
                            returnValue[enc.encryptionType] = [addr]
                        } else {
                            returnValue[enc.encryptionType]!.append(addr)
                        }
                        inserted = true
                    }
                }
            }
            if !inserted {
                if returnValue[EncryptionType.unknown] == nil {
                    returnValue[EncryptionType.unknown] = [addr]
                } else {
                    returnValue[EncryptionType.unknown]!.append(addr)
                }
            }
        }
        return returnValue
    }
    
    //a mailaddress can be found multiple encryptionTypes
    static func sortMailaddressesByEncryptionMCOAddress(_ mailaddresses: [String]) -> [EncryptionType: [MCOAddress]] {
        //TODO add different Encryptions here. This may be done via an attribute Mail_Address, setting the preffered encryption
        var returnValue : [EncryptionType : [MCOAddress]] = [:]
        var inserted : Bool
        for addr in mailaddresses {
            inserted = false
            for (_, enc) in encryptions {
                if let array = enc.getKeyIDs(addr) {
                    if array != [] {
                        if returnValue[enc.encryptionType] == nil {
                            returnValue[enc.encryptionType] = [MCOAddress(displayName: "", mailbox: addr)]
                        } else {
                            returnValue[enc.encryptionType]!.append(MCOAddress(displayName: "", mailbox: addr))
                        }
                        inserted = true
                    }
                }
            }
            if !inserted {
                if returnValue[EncryptionType.unknown] == nil {
                    returnValue[EncryptionType.unknown] = [MCOAddress(displayName: "", mailbox: addr)]
                } else {
                    returnValue[EncryptionType.unknown]!.append(MCOAddress(displayName: "", mailbox: addr))
                }
            }
        }
        return returnValue
    }
    
    //-----------------------------------------------------------------------------------------
    
    private var keychain : Keychain
    
    
    private init(){
        keychain = Keychain(service: "Enzevalos")//FIXME: .accessibility(.WhenUnlocked)
    }
    
    func hasPersistentData(_ searchKey: String, encryptionType: EncryptionType) -> Bool {
        return getPersistentData(searchKey, encryptionType: encryptionType) != nil
    }
    
    //handle entrys in keychain for different Encryptions
    func addPersistentData(_ data: Data, searchKey: String, encryptionType: EncryptionType) {
        let testData = try? keychain.getData(encryptionType.rawValue+"-"+searchKey)
        if let tmp = testData, tmp == nil {
            keychain[data: encryptionType.rawValue+"-"+searchKey] = data
        }
        
    }
    
    //for all encryptions
    /*func getPersistentData(searchKey: String) -> NSData? {
        
    }*/
    
    //for given encryption
    func getPersistentData(_ searchKey: String, encryptionType: EncryptionType) -> Data? {
        return (try! keychain.getData(encryptionType.rawValue+"-"+searchKey))
    }
    
    func replacePersistentData(_ searchKey: String, replacementData: Data, encryptionType: EncryptionType) {
        if !self.hasPersistentData(searchKey, encryptionType: encryptionType){//let tmp = (try? keychain.getData(encryptionType.rawValue+"-"+searchKey)), _ = tmp {
            return
        }
        keychain[data: encryptionType.rawValue+"-"+searchKey] = replacementData
    }
    
    func deletePersistentData(_ searchKey: String, encryptionType: EncryptionType) {
        let testData = try? keychain.getData(encryptionType.rawValue+"-"+searchKey)
        if let tmp = testData, tmp == nil {
            return
        }
        keychain[data: encryptionType.rawValue+"-"+searchKey] = nil
    }
}
