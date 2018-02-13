//
//  GTMAppAuthDelegate.swift
//  enzevalos_iphone
//
//  Created by Joscha on 01.02.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

class GTMAppAuthDelegate: NSObject, OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate {
    func didChange(_ state: OIDAuthState) {
        print("State: \(state)")
    }
    
    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        print("AuthState: \(state); Error: \(error)")
    }
}
