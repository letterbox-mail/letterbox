//
//  EnzevalosEncryptionHandler.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 13.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

//statisch von außen drauf zugreifen; auf Objekt von Encryption aus.
class EnzevalosEncryptionHandler : EncryptionHandler {
    private static let handler = EnzevalosEncryptionHandler()
    
    static func getEncryption(encryptionType: EncryptionType) -> Encryption {
    
    }
    
    private init(){
        
    }
}
