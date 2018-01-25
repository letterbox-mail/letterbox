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
    mailDraftRead = "mailDraftRead",
    mailSent = "mailSent",
    mailDeletedPersistent = "mailDeletedPersistent",
    mailDeletedToTrash = "mailDeletedToTrash",
    mailArchived = "mailArchived",
    mailReceived = "mailReceived",
    appStart = "appStart",
    appTerminate = "appTerminate",
    appBackground = "appBackground",
    overviewInbox = "overviewInbox",
    overviewGeneral = "overviewGeneral",
    keyViewOpen = "keyViewOpen",
    keyViewClose = "keyViewClose",
    contactViewOpen = "contactViewOpen",
    contactViewClose = "contactViewClose",
    badgeCaseViewOpen = "badgeCaseViewOpen",
    badgeCaseViewClose = "badgeCaseViewClose",
    pubKeyDiscoveryNewKey = "pubKeyDiscoveryNewKey",
    pubKeyDiscoveryKnownKey = "pubKeyDiscoveryKnownKey",
    pubKeyVerification = "pubKeyVerification",
    indicatorButtonOpen = "indicatorButtonOpen",
    indicatorButtonClose = "indicatorButtonClose",
    showBrokenMail = "showBrokenMail",
    reactButtonTapped = "reactButtonTapped",
    search = "search"
}
