//
//  InvitationOption.swift
//  enzevalos_iphone
//
//  Created by Konstantin Deichmann on 18.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import UIKit

enum InvitationOption {

	case welcome

	var title: String? {
		switch self {
		case .welcome		: return "Welcome"
		}
	}

	var message: String? {
		switch self {
		case .welcome		: return "Message\nMultiline and long texts are allowed, btw second button is hidden"
		}
	}

	var ctaButtonTitle: String? {
		switch self {
		case .welcome		: return "Code Teilen"
		}
	}

	var dismissButtonTitle: String? {
		switch self {
		case .welcome		: return nil
		}
	}
}
