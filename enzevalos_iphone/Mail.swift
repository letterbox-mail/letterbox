//
//  Mail.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 16/05/17.
//  Copyright © 2018 fu-berlin.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
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
    var predecessor: PersistentMail? { get }
}

public func == <T: Mail> (lhs: T, rhs: T) -> Bool {
    return lhs.date == rhs.date && lhs.uid == rhs.uid
    //TODO: update see: https://www.limilabs.com/blog/unique-id-in-imap-protocol
}

public func << T: Mail > (lhs: T, rhs: T) -> Bool {
    return lhs.date > rhs.date
}
