//
//  LoggingEventType.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 16.11.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation

enum LoggingEventType: String {
    case
    unknown = "unknown",
    mailRead = "mailRead",
    mailSent = "mailSent",
    mailReceived = "mailReceived",
    appStart = "appStart",
    appTerminate = "appTerminate",
    appBackground = "appBackground",
    overviewInbox = "overviewInbox",
    overviewGeneral = "overviewGeneral",
    keyViewOpen = "keyViewOpen",
    keyViewClose = "keyViewClose"
}