//
//  CNContactExtension.swift
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

extension CNContact: Contact {

    public var cnContact: CNContact? {
        return self
    }

    public var name: String {
        var name: String
        name = String()
        if self.givenName.count > 0 {
            name += self.givenName
        }
        if self.familyName.count > 0 {
            if name.count > 0 {
                name += " "
            }
            name += self.familyName
        }
        if name.count == 0 && self.emailAddresses.count > 0 {
            let adr = (self.emailAddresses.first?.value)! as String
            return adr
        }
        return name
    }

    public func getMailAddresses() -> [MailAddress] {
        var adr: [MailAddress] = []
        for a in self.emailAddresses {
            adr.append(CNMailAddressExtension(addr: a.value))
        }
        return adr
    }

}
