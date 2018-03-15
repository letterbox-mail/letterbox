//
//  SendViewState.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 15.03.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

protocol SendViewStateObserver {
    func stateChanged()
}

struct SendViewOptions: OptionSet {
    let rawValue: UInt8
    
    static let isLetter = SendViewOptions(rawValue: 1 << 0)
    static let isDowngraded = SendViewOptions(rawValue: 1 << 1)
    static let isPartiallyEncrypted = SendViewOptions(rawValue: 1 << 2)
    static let isCensored = SendViewOptions(rawValue: 1 << 3)
    static let hideInviteButton = SendViewOptions(rawValue: 1 << 4)
    static let sendInProgress = SendViewOptions(rawValue: 1 << 5)
}

class SendViewState: Comparable {
    
    static let Postcard = SendViewState(options: SendViewOptions(rawValue: 0))
    static let DowngradedPostcard = SendViewState(options: .isDowngraded)
    static let PartiallyEncryptedPostcard = SendViewState(options: .isPartiallyEncrypted)
    static let CensoredPostcard = SendViewState(options: .isCensored)
    static let Letter = SendViewState(options: .isLetter)
    static let DowngradedLetter = SendViewState(options: [.isLetter, .isDowngraded])
    
    var rawValue: UInt8 {
        didSet {
            if let observer = observer {
                observer.stateChanged()
            }
        }
    }
    var observer: SendViewStateObserver?
    
    init(options: SendViewOptions) {
        self.rawValue = options.rawValue
    }
    
    var isLetter: Bool {
        get {
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
        }
    }
    
    var isDowngraded: Bool {
        get {
            return SendViewOptions(rawValue: self.rawValue).contains(SendViewOptions.isDowngraded)
        }
        set(value) {
            var state = SendViewOptions(rawValue: self.rawValue)
            if state.contains(SendViewOptions.isDowngraded) == value {
                return
            }
            if state.contains(SendViewOptions.isDowngraded) {
                state.remove(SendViewOptions.isDowngraded)
            }
            if value {
                state = state.union(SendViewOptions.isDowngraded)
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
    
    var hideInviteButton: Bool {
        get {
            return SendViewOptions(rawValue: self.rawValue).contains(SendViewOptions.hideInviteButton)
        }
        set(value) {
            var state = SendViewOptions(rawValue: self.rawValue)
            if state.contains(SendViewOptions.hideInviteButton) == value {
                return
            }
            if state.contains(SendViewOptions.hideInviteButton) {
                state.remove(SendViewOptions.hideInviteButton)
            }
            if value {
                state = state.union(SendViewOptions.hideInviteButton)
            }
            self.rawValue = state.rawValue
        }
    }
    
    var sendInProgress: Bool {
        get {
            return SendViewOptions(rawValue: self.rawValue).contains(SendViewOptions.sendInProgress)
        }
        set(value) {
            var state = SendViewOptions(rawValue: self.rawValue)
            if state.contains(SendViewOptions.sendInProgress) == value {
                return
            }
            if state.contains(SendViewOptions.sendInProgress) {
                state.remove(SendViewOptions.sendInProgress)
            }
            if value {
                state = state.union(SendViewOptions.sendInProgress)
            }
            self.rawValue = state.rawValue
        }
    }
    
    static func <(lhs: SendViewState, rhs: SendViewState) -> Bool { //hier ggf. nur auf securtiy states achten
        return lhs.rawValue < rhs.rawValue
    }
    
    static func ==(lhs: SendViewState, rhs: SendViewState) -> Bool { //hier ggf. nur auf securtiy states achten
        return lhs.rawValue == rhs.rawValue
    }
    
}
