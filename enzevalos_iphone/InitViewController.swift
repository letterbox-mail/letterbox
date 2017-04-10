//
//  InitViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 14.12.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation
import UIKit

class InitViewController : UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getDefaultSettings()
    }
    
    func getDefaultSettings(){
        let manager = MCOMailProvidersManager.shared()//.init() //sharedManager()
        print(manager)
        let path = Bundle.main.path(forResource: "providers", ofType: "json")
        print(path)
        //manager.registerProvidersWithFilename(path)
        print(manager.providerForEmail("alice2005@yahoo.com") == nil)
        print(manager.providerForEmail("alice2005@aol.com") == nil)
        print(manager.providerForEmail("aol.com") == nil)
        print(manager.providerForMX("imap.aol.com") == nil)
        print(manager.providerForMX("web") == nil)
        print(manager.providerForMX("web.de") == nil)
        print(manager.providerForIdentifier("web") == nil)
        print(manager.providerForIdentifier("web.de") == nil)
        print(manager.providerForIdentifier("alice2005@aol.com") == nil)
        print(manager.providerForIdentifier("aol") == nil)
        print(manager.providerForIdentifier("aol.com") == nil)
    }
    
}
