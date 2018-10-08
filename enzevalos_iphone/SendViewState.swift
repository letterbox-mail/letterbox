//
//  SendViewState.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 15.03.18.
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

enum SendViewContactSecurityState {
    case none, allSecure, allInsecure, mixed
}

enum SendViewMailSecurityState: Equatable {
    case letter, postcard, extendedPostcard(SendViewSpecialMailState)

    var rawValue: Int {
        get {
            switch self {
            case .letter: return 0
            case .postcard: return 1
            case .extendedPostcard(_): return 2
            }
        }
    }

    static func == (lhs: SendViewMailSecurityState, rhs: SendViewMailSecurityState) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

enum SendViewSpecialMailState {
    case partiallyEncrypted, censored
}
