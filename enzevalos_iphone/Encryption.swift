//
//  Encryption.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 11.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

public protocol Encryption {
    
    func isUsed(mail: Mail) -> Bool
    func isUsed(text: String, key: KeyWrapper) -> Bool
    func isUsedForEncryption(mail: Mail) -> Bool
    func isUsedForEncrption(text: String, key: KeyWrapper) -> Bool
    func isUsedSignature(mail: Mail) -> Bool
    func isUsedSignature(text: String, key: KeyWrapper) -> Bool
    func decrypt(mail: Mail)
    func decrypt(text: String, key: KeyWrapper) -> String
    func isCorrectlySigned(mail: Mail) -> Bool
    func isCorrectlySigned(text: String, key: KeyWrapper) -> Bool
    func encrypt(mail: Mail)
    func encrypt(text: String, key: KeyWrapper) -> String
    func sign(mail: Mail)
    func sign(text: String, key: KeyWrapper) -> String
}
