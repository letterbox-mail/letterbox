//
//  MailHandlerDelegator.swift
//  enzevalos_iphone
//
//  Created by Joscha on 05.10.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation

protocol MailHandlerDelegator {
    func addNewMail(_ mail: Mail)
    func getMailCompleted()
}
