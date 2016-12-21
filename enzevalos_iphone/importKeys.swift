//
//  importKeys.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 01.12.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation

func importPrivateKey(){
    var handler = CryptoHandler.getHandler()
    var path = NSBundle.mainBundle().pathForResource("alice2005-private", ofType: "gpg")
    handler.pgp.importKeysFromFile(path!, allowDuplicates: true/*false*/)
    //KeyHandler.createHandler().addKey(handler.pgp.keys[0])
    KeyHandler.createHandler().addPrivateKey(handler.pgp.keys[0])
}

func importPublicKey(){
    var handler = CryptoHandler.getHandler()
    var path = NSBundle.mainBundle().pathForResource("alice2005-2", ofType: "gpg")
    handler.pgp.importKeysFromFile(path!, allowDuplicates: true/*false*/)
    KeyHandler.createHandler().addKey(handler.pgp.keys[0])
    //KeyHandler.createHandler().addPrivateKey(handler.pgp.keys[0])
}
