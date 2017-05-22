//
//  Mail.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 16/05/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation


public protocol Mail: Comparable {

    var cc: NSSet? { get }
    var bcc: NSSet? { get }
    var to: NSSet { get }
    var date: Date { get }
    var subject: String? { get }
    var body: String? { get }
    var uid: UInt64 { get }
}

public func == <T: Mail> (lhs: T, rhs: T) -> Bool {
    return lhs.date == rhs.date && lhs.uid == rhs.uid
}

public func << T: Mail > (lhs: T, rhs: T) -> Bool {
    return lhs.date > rhs.date
}
