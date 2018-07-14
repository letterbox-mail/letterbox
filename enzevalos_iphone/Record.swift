//
//  Record.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 06/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
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
