//
//  KeyWrapper.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 13.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

public protocol KeyWrapper {
    
    var revoked: Bool {get set}
    var revokeTime: NSDate {get}
    var trustlevel: Int {get set}
    var verified: Bool {get set}
    var verifyTime: NSDate {get}
    var discoveryTime: NSDate {get}
    var discoveryMailUID: UInt64? {get}
    var type: EncryptionType {get}
    var keyID: String {get}
    
    init(coder: NSCoder)
    
    func encodeWithCoder(coder: NSCoder)
}
