//
//  Encryption.swift
//  ObjectivePGP
//
//  Created by Oliver Wiese on 25.09.17.
//  Copyright © 2017 Marcin Krzyżanowski. All rights reserved.
//

import Foundation

public protocol Encryption{
    
    // Key handling
    func generateKey(adr: String) -> String
    func importKeys(key: String, isSecretKey: Bool, autocrypt: Bool) -> [String]
    func importKeys(data: Data, secret: Bool) -> [String]
    func importKeysFromFile(file: String) -> [String]
    func exportKey(id: String, isSecretkey: Bool, autocrypt: Bool) -> String?
    
    // operations on keys
    func encrypt(plaintext: String, ids: [String], myId: String) -> CryptoObject
    func decrypt(data: Data, decryptionId: String?, verifyIds: [String]) -> CryptoObject

}