//
//  PGPTemporaryDecryptionObject.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 09.02.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//


class PGPTemporaryDecryptionObject {
    let onePassSignaturePacket: PGPOnePassSignaturePacket
    let signaturePacket: PGPSignaturePacket
    let plaintextData: Data?
    
    init(onePassSignaturePacket: PGPOnePassSignaturePacket, signaturePacket: PGPSignaturePacket, plaintextData: Data?){
        self.onePassSignaturePacket = onePassSignaturePacket
        self.signaturePacket = signaturePacket
        self.plaintextData = plaintextData
    }
    
}
