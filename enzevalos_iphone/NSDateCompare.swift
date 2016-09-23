//
//  NSDateCompare.swift
//  readView
//
//  Created by Joscha on 09.09.16.
//  Copyright © 2016 Joscha. All rights reserved.
//

import Foundation

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs === rhs || lhs.compare(rhs) == .OrderedSame
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == .OrderedAscending
}

extension NSDate: Comparable { }