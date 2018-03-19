//
//  SendViewState.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 15.03.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

protocol SendViewSecurityStateObserver {
    var recipientSecurityState: SendViewContactSecurityState { get }
    
    func securityStateChanged()
}

struct SendViewOptions: OptionSet {
    let rawValue: UInt8
    
    static let isLetter = SendViewOptions(rawValue: 1 << 0)
    static let enforcePostcard = SendViewOptions(rawValue: 1 << 1)
    static let isPartiallyEncrypted = SendViewOptions(rawValue: 1 << 2)
    static let isCensored = SendViewOptions(rawValue: 1 << 3)
}

class SendViewSecurityState: Equatable {
    
    static let Postcard = SendViewSecurityState(options: SendViewOptions(rawValue: 0))
    static let EnforcedPostcard = SendViewSecurityState(options: .enforcePostcard)
    static let PartiallyEncryptedPostcard = SendViewSecurityState(options: .isPartiallyEncrypted)
    static let CensoredPostcard = SendViewSecurityState(options: .isCensored)
    static let Letter = SendViewSecurityState(options: .isLetter)
    static let LetterEnforcedAsPostcard = SendViewSecurityState(options: [.isLetter, .enforcePostcard])
    
    var rawValue: UInt8 {
        didSet {
            if let observer = observer {
                observer.securityStateChanged()
            }
        }
    }
    var observer: SendViewSecurityStateObserver?
    
    init(options: SendViewOptions) {
        self.rawValue = options.rawValue
    }
    
    var isLetter: Bool {  //Wie mit Zustandsänderung umgehen? (passiert jetzt nicht automatisiert, sondern erst auf anfrage, oder...?)
        get {
            if !enforcePostcard && (observer?.recipientSecurityState == .allSecure || observer?.recipientSecurityState == .none) {
                return true
            }
            return false
        }
        /*get {
            return SendViewOptions(rawValue: self.rawValue).contains(SendViewOptions.isLetter)
        }
        set(value) {
            var state = SendViewOptions(rawValue: self.rawValue)
            if state.contains(SendViewOptions.isLetter) == value {
                return
            }
            if state.contains(SendViewOptions.isLetter) {
                state.remove(SendViewOptions.isLetter)
            }
            if value {
                state = state.union(SendViewOptions.isLetter)
            }
            self.rawValue = state.rawValue
        }*/
    }
    
    var enforcePostcard: Bool {
        get {
            return SendViewOptions(rawValue: self.rawValue).contains(SendViewOptions.enforcePostcard)
        }
        set(value) {
            var state = SendViewOptions(rawValue: self.rawValue)
            if state.contains(SendViewOptions.enforcePostcard) == value {
                return
            }
            if state.contains(SendViewOptions.enforcePostcard) {
                state.remove(SendViewOptions.enforcePostcard)
            }
            if value {
                state = state.union(SendViewOptions.enforcePostcard)
            }
            self.rawValue = state.rawValue
        }
    }
    
    var isPartiallyEncrypted: Bool {
        get {
            return SendViewOptions(rawValue: self.rawValue).contains(SendViewOptions.isPartiallyEncrypted)
        }
        set(value) {
            var state = SendViewOptions(rawValue: self.rawValue)
            if state.contains(SendViewOptions.isPartiallyEncrypted) == value {
                return
            }
            if state.contains(SendViewOptions.isPartiallyEncrypted) {
                state.remove(SendViewOptions.isPartiallyEncrypted)
            }
            if value {
                state = state.union(SendViewOptions.isPartiallyEncrypted)
            }
            self.rawValue = state.rawValue
        }
    }
    
    var isCensored: Bool {
        get {
            return SendViewOptions(rawValue: self.rawValue).contains(SendViewOptions.isCensored)
        }
        set(value) {
            var state = SendViewOptions(rawValue: self.rawValue)
            if state.contains(SendViewOptions.isCensored) == value {
                return
            }
            if state.contains(SendViewOptions.isCensored) {
                state.remove(SendViewOptions.isCensored)
            }
            if value {
                state = state.union(SendViewOptions.isCensored)
            }
            self.rawValue = state.rawValue
        }
    }
    
    static func ==(lhs: SendViewSecurityState, rhs: SendViewSecurityState) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
}


enum SendViewContactSecurityState {
    case none, allSecure, allInsecure, mixed
}

enum SendViewMailSecurityState {
    case letter, postcard, extendedPostcard(SendViewSpecialMailState)
}

enum SendViewSpecialMailState {
    case partiallyEncrypted, censored
}
