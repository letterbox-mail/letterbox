//
//  LoggingEventType.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 16.11.17.
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
        onboardingState = "onboardingState",
        backgroundFetch = "backgroundFetch"
}
