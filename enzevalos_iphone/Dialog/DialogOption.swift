//
//  DialogOption.swift
//  enzevalos_iphone
//
//  Created by Konstantin Deichmann on 18.01.18.
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

import UIKit

enum DialogOption {

	case postcard
	case invitationCode(code: String)
	case invitationWelcome
	case invitationStep
    case invitationHelp

	var color: UIColor {
		switch self {
		case .postcard			: return .yellow
		case .invitationCode	: return UIColor.Invitation.orange
		case .invitationWelcome	: return UIColor.Invitation.orange
		case .invitationStep	: return UIColor.Invitation.orange
        case .invitationHelp    : return UIColor.Invitation.orange
		}
	}

	var titleImage: UIImage? {
		switch self {
		case .postcard			: return nil
		case .invitationCode	: return nil
		case .invitationWelcome, .invitationHelp :
            switch StudySettings.invitationsmode {
                case InvitationMode.Censorship:
                    var images = [UIImage]()
                    if let sender = UIImage(named: "bg_inviation_censor_sender"), let receiver = UIImage(named: "bg_inviation_censor_receiver") {
                        images.append(sender)
                        images.append(receiver)
                        return UIImage.animatedImage(with: images, duration: 4)
                    }
                    return nil
                case .PasswordEnc:
                    return UIImage(named: "bg_inviation")
                case .FreeText,
                     .InviteMail:
                    return UIImage(named: "postcard")
            }
		case .invitationStep	: return nil
		}
	}

	var icon: UIImage? {
		switch self {
		case .postcard			: return UIImage(named: "letter")
		case .invitationCode	: return UIImage(named: "ic_secure_card")
		case .invitationWelcome,
             .invitationHelp    : return nil
		case .invitationStep	: return UIImage(named: "ic_secure_card")
		}
	}

	var title: String? {
		switch self {
		case .postcard			: return "Welcome"
		case .invitationCode	: return NSLocalizedString("Invitation.Code.Title", comment: "")
		case .invitationWelcome,
             .invitationHelp    : return NSLocalizedString("Invitation.Welcome.Title", comment: "")
		case .invitationStep	: return NSLocalizedString("Invitation.Step.Title", comment: "")
		}
	}

	var message: String? {
		switch self {
		case .postcard			: return "Message\nMultiline and long texts are allowed, btw second button is hidden"
		case .invitationWelcome,
             .invitationHelp    :
            switch StudySettings.invitationsmode {
                case .Censorship    : return NSLocalizedString("Invitation.Welcome.Message.Censor", comment: "")
                case .FreeText,
                     .InviteMail    : return NSLocalizedString("Invitation.Welcome.Message.InvitationMail", comment: "")
                case .PasswordEnc   : return NSLocalizedString("Invitation.Welcome.Message", comment: "")
            }
		case .invitationStep	:
            if StudySettings.invitationsmode == InvitationMode.Censorship{
                return NSLocalizedString("Invitation.Step.Message.Censor", comment: "")
            }
            return NSLocalizedString("Invitation.Step.Message", comment: "")
		case .invitationCode(let code)	:
            if StudySettings.invitationsmode == InvitationMode.Censorship{
                return ""
            }
			return String(format: NSLocalizedString("Invitation.Code.Message", comment: ""), code)
		}
	}

	var ctaButtonTitle: String? {
		switch self {
		case .postcard			: return "Freunde einladen"
		case .invitationCode	: return NSLocalizedString("Invitation.Code.Share", comment: "")
		case .invitationWelcome	:
            switch StudySettings.invitationsmode {
                case .FreeText,
                     .InviteMail    : return NSLocalizedString("Invitation.Welcome.Try.InvitationMail", comment: "")
                case .Censorship,
                     .PasswordEnc   : return NSLocalizedString("Invitation.Welcome.Try", comment: "")
            }
		case .invitationStep	: return NSLocalizedString("Invitation.Step.CTA", comment: "")
        case .invitationHelp    : return NSLocalizedString("Done", comment: "")
		}
	}

	var additionActionButtonTitle: String? {
		switch self {
		case .postcard			: return "Mehr Informationen"
		case .invitationCode	: return nil
		case .invitationWelcome	: return NSLocalizedString("Invitation.Welcome.Later", comment: "")
        case .invitationStep	: return nil
        case .invitationHelp    : return nil
		}
	}

	var dismissButtonTitle: String? {
		switch self {
		case .postcard			: return "OK"
		case .invitationCode	: return NSLocalizedString("Invitation.Code.Done", comment: "")
		case .invitationWelcome	: return NSLocalizedString("Invitation.Welcome.Dont.Ask", comment: "")
		case .invitationStep	: return NSLocalizedString("Invitation.Step.Undo", comment: "")
        case .invitationHelp    : return nil
		}
	}
}
