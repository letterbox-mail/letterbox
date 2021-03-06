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
    case NoPublicKey
    case InvalidSignature
    case ValidSignature
}

enum EncryptionState {
    case NoEncryption
    case UnableToDecrypt
    case ValidEncryptedWithOldKey
    case ValidedEncryptedWithCurrentKey
}

public enum CryptoScheme {
    case PGP
    case UNKNOWN

    var description: String {
        switch self {
        case .PGP:
            return "PGP"
        default:
            return ""
        }
    }

    static func find(i: Int) -> CryptoScheme {
        switch i {
        case 0:
            return CryptoScheme.PGP
        default:
            return CryptoScheme.UNKNOWN
        }
    }
    func asInt() -> Int16 {
        switch self {
        case CryptoScheme.PGP:
            return 0
        case CryptoScheme.UNKNOWN:
            return 99
        }
    }
}

public class CryptoObject {
    let chiphertext: Data?
    let plaintext: String?
    let decryptedData: Data?
    let signatureState: SignatureState
    var encryptionState: EncryptionState
    let signKey: String?
    let encType: CryptoScheme
    let passcode: String?
    let signedAdrs: [String]

    var decryptedText: String? {
        if let data = decryptedData {
            return String.init(data: data, encoding: .utf8)
        }
        return nil
    }


    init(chiphertext: Data?, plaintext: String?, decryptedData: Data?, sigState: SignatureState, encState: EncryptionState, signKey: String?, encType: CryptoScheme, signedAdrs: [String]) {
        self.chiphertext = chiphertext
        self.plaintext = plaintext
        self.decryptedData = decryptedData
        self.signatureState = sigState
        self.encryptionState = encState
        self.signKey = signKey
        self.encType = encType
        self.passcode = nil
        self.signedAdrs = signedAdrs
    }




}
