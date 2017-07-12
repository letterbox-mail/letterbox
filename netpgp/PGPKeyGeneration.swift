//
//  PGPKeyGeneration.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation


public func createKey(userID:String){
    var adr: UInt8
    adr = 8
   var pk: Array<CChar> = Array(repeating: 32, count: 4048)
   //var sk: Array<CChar> = Array(repeating: 32, count: 4048)
   
    var sk: pgp_key_t = generateSecretKey(&adr)
    
    print("CreateKey")
    mre2ee_driver_create_keypair(&adr, &pk, &pk)
    
    
    print("###########")
    
    
    
}




