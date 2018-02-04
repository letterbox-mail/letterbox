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
	case invitationCode(code: String)
	case invitationWelcome
	case invitationStep

	var color: UIColor {
		switch self {
		case .postcard			: return .yellow
		case .invitationCode	: return UIColor.Invitation.orange
		case .invitationWelcome	: return UIColor.Invitation.orange
		case .invitationStep	: return UIColor.Invitation.orange
		}
	}

	var icon: UIImage? {
		switch self {
		case .postcard			: return UIImage(named: "letter")
		case .invitationCode	: return UIImage(named: "ic_secure_card")
		case .invitationWelcome	: return UIImage(named: "ic_secure_card")
		case .invitationStep	: return UIImage(named: "ic_secure_card")
		}
	}

	var title: String? {
		switch self {
		case .postcard			: return "Welcome"
		case .invitationCode	: return NSLocalizedString("Invitation.Code.Title", comment: "")
		case .invitationWelcome	: return NSLocalizedString("Invitation.Welcome.Title", comment: "")
		case .invitationStep	: return NSLocalizedString("Invitation.Step.Title", comment: "")
		}
	}

	var message: String? {
		switch self {
		case .postcard			: return "Message\nMultiline and long texts are allowed, btw second button is hidden"
		case .invitationWelcome	: return NSLocalizedString("Invitation.Welcome.Message", comment: "")
		case .invitationStep	: return NSLocalizedString("Invitation.Step.Message", comment: "")
		case .invitationCode(let code)	:
			return String(format: NSLocalizedString("Invitation.Code.Message", comment: ""), code)
		}
	}

	var ctaButtonTitle: String? {
		switch self {
		case .postcard			: return "Freunde einladen"
		case .invitationCode	: return NSLocalizedString("Invitation.Code.Share", comment: "")
		case .invitationWelcome	: return NSLocalizedString("Invitation.Welcome.Try", comment: "")
		case .invitationStep	: return NSLocalizedString("Invitation.Step.CTA", comment: "")
		}
	}

	var additionActionButtonTitle: String? {
		switch self {
		case .postcard			: return "Mehr Informationen"
		case .invitationCode	: return nil
		case .invitationWelcome	: return NSLocalizedString("Invitation.Welcome.Later", comment: "")
		case .invitationStep	: return nil
		}
	}

	var dismissButtonTitle: String? {
		switch self {
		case .postcard			: return "OK"
		case .invitationCode	: return NSLocalizedString("Invitation.Code.Done", comment: "")
		case .invitationWelcome	: return NSLocalizedString("Invitation.Welcome.Dont.Ask", comment: "")
		case .invitationStep	: return NSLocalizedString("Invitation.Step.Undo", comment: "")
		}
	}
}
