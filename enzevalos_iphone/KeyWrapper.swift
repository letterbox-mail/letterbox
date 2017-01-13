//
//  KeyWrapper.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 13.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

public protocol KeyWrapper {
    
    var revoked: Bool
    var revokeTime: NSDate
    var trustlevel: Int
    var verified: Bool
    var trustTime: NSDate
    var discoveryTime: NSDate
    
    init(coder: NSCoder)
    
    func encodeWithCoder(coder: NSCoder)
}
