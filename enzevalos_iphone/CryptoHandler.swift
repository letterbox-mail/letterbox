//
//  CryptoHandler.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 11.11.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation

class CryptoHandler {
    private static var handler : CryptoHandler? = nil
    var pgp : ObjectivePGP
    private init(){
        pgp = ObjectivePGP.init()
    }
    static func getHandler() -> CryptoHandler{
        if CryptoHandler.handler == nil {
            CryptoHandler.handler = CryptoHandler.init()
        }
        return CryptoHandler.handler!
    }
}
