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
        let manager = MCOMailProvidersManager.shared()!//.init() //sharedManager()
        let path = Bundle.main.path(forResource: "providers", ofType: "json")
        manager.registerProviders(withFilename: path)
    }
    
}
