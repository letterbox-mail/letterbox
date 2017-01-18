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
    
    
    
    //handle entrys in keychain for different Encryptions
    func addPersistentData(data: NSData, searchKey: String, encryptionType: EncryptionType, callBack: ((success: Bool) -> Void)?)
    //for all encryptions
    func getPersistentData(searchKey: String) -> NSData?
    //for given encryption
    func getPersistentData(searchKey: String, encryptionType: EncryptionType) -> NSData?
    func replacePersistentData(searchKey: String, replacementData: NSData, encryptionType: EncryptionType, callBack: ((success: Bool) -> Void)?)
    func deletePersistentData(searchKey: String, encryptionType: EncryptionType, callBack: ((success: Bool) -> Void)?)
    
}
