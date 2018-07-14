//
//  Badges.swift
//  enzevalos_iphone
//
//  Created by Moritz on 24.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit




/**
 Enum Type for easier Recogition.
 */
enum BadgeType: Int {
    case keyMaster
    case trustmaster
    case encMaster
    case firstMail
    case quizmaster
    case onBoarding
    case inviteAFriend
    case Ambassador

    case MailMaster
    case MailMaster1
    case MailMaster10
    case MailMaster50
    case MailMaster100
    case MailMaster1000


    case SecureMailMaster
    case SecureMailMaster1
    case SecureMailMaster10
    case SecureMailMaster50
    case SecureMailMaster100
    case SecureMailMaster1000
    case None // for SubBadge
}

/**
 Identifies Achievments, needed for DataStorage, mapping Achievments with Badges, Setting Conditions for Achievments
 */
enum Achievment {
    case Firstkey
    case OneFriendInvited
    case FiveFriendsInvited
    case Mails1
    case Mails10
    case Mails50
    case Mails100
    case Mails1000
    case SecureMails1
    case SecureMails10
    case SecureMails50
    case SecureMails100
    case SecureMails1000
    case SecureSend
    case SecureReceived
}

/**
    Segues used By Badges
 */
enum SegueName {
    case LinearBadge
    case inviteFriend
    case None // for SubBadge
}


class Badges: NSObject {
    // MARK:- Variables
    let type: BadgeType

    // Picture Names
    let offName: String
    let onName: String
    let segueName: SegueName
    let displayName: String
    let achievments: [Achievment]?

    // MARK:- Functions
    /**
     - Parameter type: BadgeType, see enum type BadgeType. **Default:** .None
     - Parameter pictureOff: String for picture name of uncompleted Badge
     - Parameter pictureOn: String for picture name of finished Badge
     - Parameter segue: Name of the Segue leading to correct BadgeDetail Controller, **Default:** .None
     - Parameter displayName: Name Displayed in badge Case and elsewhere
     - Parameter achievmentsNeeded: Achievments needed to Complete this Badge, if nil Badge is always Completed
     */
    init(type: BadgeType = .None, pictureOff: String, pictureOn: String, segue: SegueName = .None, displayName: String, achievmentsNeeded: [Achievment]? = nil) {
        self.type = type
        self.offName = pictureOff
        self.onName = pictureOn
        self.segueName = segue
        self.displayName = displayName
        self.achievments = achievmentsNeeded
        super.init()
    }




    /**
     Returns the current Image for the Badge.Handles Achieved/not Achieved
     */
    func badgeImage() -> UIImage {

        var image: UIImage?
        if (GamificationData.sharedInstance.badgeAchieved(badge: self)) {
            image = UIImage.init(named: onName)
        } else {
            image = UIImage.init(named: offName)
        }
        guard let unpackedImage = image else {
            fatalError("Badge Image not found. Please Check Image Names. names tried: \(onName) and \(offName)\n")
        }

        return unpackedImage
    }

    /**
        returns True if this Badge is Achieved
     */
    func isAchieved() -> Bool {
        return GamificationData.sharedInstance.badgeAchieved(badge: self)
    }

}

extension UIColor {
    class func badgeGreen() -> UIColor {
        return UIColor(red: 37 / 255, green: 132 / 255, blue: 6 / 255, alpha: 1)
    }

}
