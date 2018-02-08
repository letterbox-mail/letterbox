//
//  StudySettings.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 08.02.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation
import KeychainAccess

class StudySettings {
    static var studyMode = true
    
    static func setupStudy() {
        if !studyMode {
            //Logger.logging = false
            return
        }
        Logger.logging = true
        
        let keychain = Keychain(service: "Enzevalos/Study")
        if let state = keychain["hideWarnings"] {
            UserDefaults.standard.set(Bool(state), forKey: "hideWarnings")
        } else {
            var warnings = true
            var randomBytes = Data(count: 1)
            let result = randomBytes.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, $0)
            }
            if result == errSecSuccess {
                warnings = randomBytes[0] >= 128
            } else {
                print("Problem generating random bytes")
                warnings = Int(arc4random_uniform(2)) == 0
            }
            keychain["hideWarnings"] = String(warnings)
            UserDefaults.standard.set(warnings, forKey: "hideWarnings")
        }
        
        var alreadyParticipant = false
        
        if let studyID = keychain["studyID"] {
            alreadyParticipant = true
            UserDefaults.standard.set(studyID, forKey: "studyID")
            Logger.studyID = studyID
        } else {
            let studyID = String.random(length: 30)
            keychain["studyID"] = studyID
            UserDefaults.standard.set(studyID, forKey: "studyID")
        }
        
    }
    //create local mail for first interview here
}
