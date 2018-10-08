//
//  EphemeralMail.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 17/05/17.
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

open class EphemeralMail: Mail {

    public var cc: NSSet?
    public var bcc: NSSet?
    public var to: NSSet
    public var date: Date
    public var subject: String?
    public var body: String?
    public var uid: UInt64
    public var predecessor: PersistentMail?

    public init(to: NSSet = [], cc: NSSet = [], bcc: NSSet = [], date: Date = Date(), subject: String? = nil, body: String? = ""/*UserManager.loadUserSignature()*/, uid: UInt64 = 0, predecessor: PersistentMail? = nil) {
        self.cc = cc
        self.bcc = bcc
        self.to = to
        self.body = body
        self.date = date
        self.subject = subject
        self.uid = uid
        self.predecessor = predecessor
    }
}
