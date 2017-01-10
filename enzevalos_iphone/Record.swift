//
//  Record.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 06/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

public protocol Record: Comparable {
    var name: String{get}
    var isSecure: Bool{get}
    var isVerified: Bool {get}
    func getContact()-> EnzevalosContact
    func getFromMails()->[Mail]
    func updateMails(mail:Mail)->Bool
}
