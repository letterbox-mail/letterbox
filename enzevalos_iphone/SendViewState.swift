//
//  SendViewState.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 15.03.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

enum SendViewContactSecurityState {
    case none, allSecure, allInsecure, mixed
}

enum SendViewMailSecurityState: Equatable {
    case letter, postcard, extendedPostcard(SendViewSpecialMailState)
    
    var rawValue: Int {
        get {
            switch self {
                case .letter: return 0
                case .postcard: return 1
                case .extendedPostcard(_): return 2
            }
        }
    }
    
    static func ==(lhs:SendViewMailSecurityState, rhs:SendViewMailSecurityState) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

enum SendViewSpecialMailState {
    case partiallyEncrypted, censored
}
