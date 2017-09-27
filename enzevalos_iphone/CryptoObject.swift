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
    let signatureState: SignatureState
    let encryptionState: EncryptionState
    let signKey: String?
    let encType: CryptoScheme
    
    
    init(chiphertext: Data?, plaintext: String?, sigState: SignatureState, encState: EncryptionState, signKey: String?, encType: CryptoScheme){
        self.chiphertext = chiphertext
        self.plaintext = plaintext
        self.signatureState = sigState
        self.encryptionState = encState
        self.signKey = signKey
        self.encType = encType
    }
    
    
    
    
}
