//
//  Encryption.swift
//  ObjectivePGP
//
//  Created by Oliver Wiese on 25.09.17.
//  Copyright © 2017 Marcin Krzyżanowski. All rights reserved.
//

import Foundation

public protocol Encryption {

    // Key handling
    func generateKey(adr: String, new: Bool) -> String
    func importKeys(key: String, pw: String?, isSecretKey: Bool, autocrypt: Bool) throws -> [String]
    func importKeys(data: Data, pw: String?, secret: Bool) throws -> [String]
    func importKeysFromFile(file: String, pw: String?) throws -> [String]

    func exportKey(id: String, isSecretkey: Bool, autocrypt: Bool, newPasscode: Bool) -> String?

    // operations on keys
    func encrypt(plaintext: String, ids: [String], myId: String) -> CryptoObject
    func decrypt(data: Data, decryptionIDs: [String], verifyIds: [String], fromAdr: String?) -> CryptoObject

}
