//
//  StringExtension.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 03.11.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
extension String {
    
    static func random(length: Int = 20) -> String {
        var randomBytes = Data(count: length)
        
        let result = randomBytes.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, $0)
        }
        if result == errSecSuccess {
            return randomBytes.base64EncodedString()
        } else {
            print("Problem generating random bytes")
            return ""
        }
    }
}
