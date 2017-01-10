//
//  Contact.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Contacts
import UIKit


public protocol Contact: Comparable {
    var name: String{get}
    var cnContact: CNContact {get}
    var color: UIColor {get}
}


