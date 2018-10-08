//
//  Record.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 06/01/17.
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
import Contacts
import UIKit


public protocol Record: Comparable {

    var name: String { get }
    var hasKey: Bool { get }
    var isVerified: Bool { get }
    var ezContact: EnzevalosContact { get }
    var mails: [PersistentMail] { get }
    var cnContact: CNContact? { get }
    var color: UIColor { get }
    var image: UIImage { get }
    var addresses: [MailAddress] { get }
}
