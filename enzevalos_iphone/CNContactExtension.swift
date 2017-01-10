//
//  CNContactExtension.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Contacts

extension CNContact: Contact{
    
    public var cnContact: CNContact?{
        return self
    }
    
    public var name: String{
        var name: String
        name = String()
        if self.givenName.characters.count > 0 {
                name += self.givenName
        }
        if self.familyName.characters.count > 0 {
            if name.characters.count > 0 {
                name += " "
            }
            name += self.familyName
        }
        if name.characters.count == 0 {
            if name == (self.emailAddresses.first?.label)! {
                return name
            }
            else{
                return "No Name"
            }
        }
        return name
    }
    
    public func getMailAddresses() -> [MailAddress] {
        var adr = [MailAddress] ()
        for a in  self.emailAddresses{
            adr.append(CNMailAddressExtension(addr: a))
        }
        return adr
    }
    
}
