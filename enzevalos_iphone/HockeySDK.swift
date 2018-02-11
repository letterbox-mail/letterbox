//
//  HockeySDK.swift
//  enzevalos_iphone
//
//  Created by Konstantin Deichmann on 03.11.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit
import HockeySDK

struct HockeySDK {

	// MARK: - Properties

	private static var identifierKey = "HockeyAppId"

	private static var isDebugBuild: Bool {
		#if DEBUG
			return true
		#else
			return false
		#endif
	}

	// MARK: - Setup

	static func setup() {

		guard let _identifierKey = Bundle.main.object(forInfoDictionaryKey: identifierKey) as? String else {
			print("Info: You have to set the `\(identifierKey)` key in the info plist.")
			return
		}

		guard (self.isDebugBuild == false) else {
			return
		}

		BITHockeyManager.shared().configure(withIdentifier: _identifierKey)
		BITHockeyManager.shared().start()
		BITHockeyManager.shared().authenticator.authenticateInstallation()
		BITHockeyManager.shared().crashManager.crashManagerStatus = .autoSend
	}
}
