//
//  DecryptedData.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 16.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
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

public class DecryptedData{
    let decryptedBody: Data?
    let signatureState: SignatureState
    let encryptionState: EncryptionState
    let keyID: String?
    let encType: EncryptionType?
    
    
    init(decryptedBody: Data?, sigState: SignatureState, encState: EncryptionState, key: String?, encType: EncryptionType?){
        self.decryptedBody = decryptedBody
        self.signatureState = sigState
        self.encryptionState = encState
        self.keyID = key
        self.encType = encType
    }
    
    


}
