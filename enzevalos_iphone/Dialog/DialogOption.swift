//
//  DialogOption.swift
//  enzevalos_iphone
//
//  Created by Konstantin Deichmann on 18.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import UIKit

enum DialogOption {

	case postcard

	var color: UIColor {
		switch self {
		case .postcard		: return .yellow
		}
	}

	var icon: UIImage? {
		switch self {
		case .postcard		: return UIImage(named: "letter")
		}
	}

	var title: String? {
		switch self {
		case .postcard		: return "Welcome"
		}
	}

	var message: String? {
		switch self {
		case .postcard		: return "Message\nMultiline and long texts are allowed, btw second button is hidden"
		}
	}

	var ctaButtonTitle: String? {
		switch self {
		case .postcard		: return "Freunde einladen"
		}
	}

	var additionActionButtonTitle: String? {
		switch self {
		case .postcard		: return "Mehr Informationen"
		}
	}

	var dismissButtonTitle: String? {
		switch self {
		case .postcard		: return "OK"
		}
	}
}
