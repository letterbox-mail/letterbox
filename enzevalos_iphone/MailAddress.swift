//
//  MailAddress.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10/01/17.
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

public enum EncState {
    case MUTAL
    case GOSSIP
    case NOPREFERENCE
    case RESET
    case NOAUTOCRYPT


    static func find(i: Int) -> EncState {
        switch i {
        case 0:
            return EncState.MUTAL
        case 1:
            return EncState.GOSSIP
        case 2:
            return EncState.NOPREFERENCE
        case 3:
            return EncState.RESET
        case 4:
            return EncState.NOAUTOCRYPT
        default:
            return EncState.NOAUTOCRYPT
        }
    }

    func canEnc() -> Bool {

        switch self {
        case EncState.MUTAL:
            return true
        case EncState.GOSSIP:
            return true
        case EncState.RESET:
            return true
        default:
            return false
        }
    }
    func asInt() -> Int16 {
        switch self {
        case EncState.MUTAL:
            return 0
        case EncState.GOSSIP:
            return 1
        case EncState.NOPREFERENCE:
            return 2
        case EncState.RESET:
            return 3
        case EncState.NOAUTOCRYPT:
            return 4
        }
    }

}

public protocol MailAddress {
    var mailAddress: String { get }
    var label: CNLabeledValue<NSString> { get } //FIXME: ist der NSString hier wirklich richtig? (http://stackoverflow.com/questions/39648830/how-to-add-new-email-to-cnmutablecontact-in-swift-3)
    // var prefEnc: EncState{get set}
    var hasKey: Bool { get }

    var primaryKey: PersistentKey? { get }
    var publicKeys: Set<PersistentKey> { get }
    var contact: EnzevalosContact? { get }
}

