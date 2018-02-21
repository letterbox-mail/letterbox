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
    mailSent = "mailSent",
    mailDeletedPersistent = "mailDeletedPersistent",
    mailDeletedToTrash = "mailDeletedToTrash",
    mailArchived = "mailArchived",
    mailReceived = "mailReceived",
    setupStudy = "setupStudy",
    appStart = "appStart",
    appTerminate = "appTerminate",
    appBackground = "appBackground",
    overviewInbox = "overviewInbox",
    overviewGeneral = "overviewGeneral",
    readViewOpen = "readViewOpen",
    readViewClose = "readViewClose",
    keyViewOpen = "keyViewOpen",
    keyViewClose = "keyViewClose",
    sendViewOpen = "sendViewOpen",
    sendViewClose = "sendViewClose",
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
    createDraft = "createDraft",
    exportKeyViewOpen = "exportKeyViewOpen",
    exportKeyViewButtonTap = "exportKeyViewButtonTap",
    exportKeyViewClose = "exportKeyViewClose",
    importPrivateKeyPopupOpen = "importPrivateKeyPopupOpen",
    importPrivateKeyPopupClose = "importPrivateKeyPopupClose",
    importPrivateKey = "importPrivateKey",
    search = "search",
    gotBitcoinMail = "gotBitcoinMail",
    onboardingPageTransition = "onboardingPageTransition",
    onboardingState = "onboardingState"
}
