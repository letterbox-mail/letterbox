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
        print(manager?.provider(forEmail: "alice2005@yahoo.com") == nil)
        print(manager?.provider(forEmail: "alice2005@aol.com") == nil)
        print(manager?.provider(forEmail: "aol.com") == nil)
        print(manager?.provider(forMX: "imap.aol.com") == nil)
        print(manager?.provider(forMX: "web") == nil)
        print(manager?.provider(forMX: "web.de") == nil)
        print(manager?.provider(forIdentifier: "web") == nil)
        print(manager?.provider(forIdentifier: "web.de") == nil)
        print(manager?.provider(forIdentifier: "alice2005@aol.com") == nil)
        print(manager?.provider(forIdentifier: "aol") == nil)
        print(manager?.provider(forIdentifier: "aol.com") == nil)
    }
    
}
