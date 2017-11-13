//
//  CryptoObject.swift
//  ObjectivePGP
//
//  Created by Oliver Wiese on 25.09.17.
//  Copyright © 2017 Marcin Krzyżanowski. All rights reserved.
//

import Foundation
enum SignatureState {
    case NoSignature
    case InvalidSignature
    case ValidSignature
}

enum EncryptionState {
    case NoEncryption
    case UnableToDecrypt
    case ValidEncryptedWithOldKey
    case ValidedEncryptedWithCurrentKey
}

enum CryptoScheme {
    case PGP
    case UNKNOWN
}

public class CryptoObject{
    let chiphertext: Data?
    let plaintext: String?
    let decryptedData: Data?
    let signatureState: SignatureState
    let encryptionState: EncryptionState
    let signKey: String?
    let encType: CryptoScheme
    let passcode: String?
    
    var decryptedText: String?{
        if let data = decryptedData{
            return String.init(data: data, encoding: .utf8)
        }
        return nil
    }
    
    
    init(chiphertext: Data?, plaintext: String?, decryptedData: Data?, sigState: SignatureState, encState: EncryptionState, signKey: String?, encType: CryptoScheme){
        self.chiphertext = chiphertext
        self.plaintext = plaintext
        self.decryptedData = decryptedData
        self.signatureState = sigState
        self.encryptionState = encState
        self.signKey = signKey
        self.encType = encType
        self.passcode = nil
    }
    
    
    
    
}
