//
//  EncryptionHandler.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 11.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

public protocol EncryptionHandler {
    //var keychain
    
    //----- static stuff -----
    // static func getEncryption(_ encryptionType: EncryptionType) -> Encryption?
    // static func hasKey(_ enzContact: EnzevalosContact) -> Bool
    // static func hasKey(_ mailAddress: String) -> Bool
    // static func getEncryptionTypeForMail(_ mail: Mail) -> EncryptionType
    // static func sortMailaddressesByEncryption(_ mailaddresses: [String]) -> [EncryptionType: [String]]
    // static func sortMailaddressesByEncryptionMCOAddress(_ mailaddresses: [String]) -> [EncryptionType: [MCOAddress]]
    
    
    //handle entrys in keychain for different Encryptions
    func addPersistentData(_ data: Data, searchKey: String, encryptionType: EncryptionType)
    //for all encryptions
    //func getPersistentData(searchKey: String) -> NSData?
    func hasPersistentData(_ searchKey: String, encryptionType: EncryptionType) -> Bool
    //for given encryption
    func getPersistentData(_ searchKey: String, encryptionType: EncryptionType) -> Data?
    func replacePersistentData(_ searchKey: String, replacementData: Data, encryptionType: EncryptionType) //-> Bool
    func deletePersistentData(_ searchKey: String, encryptionType: EncryptionType) //-> Bool
    
}
