//
//  GamificationData.swift
//  enzevalos_iphone
//
//  Created by Moritz on 27.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit
import CoreData
import Contacts

// mails anzahl
// kontakt anzahl
// secure percentage
// keys collected
// Backups / Timeframe







    /**
    Class provides and Manages all Data needed in Gamification Module
    */
class GamificationData: NSObject {

    // MARK:- Variables

    static let sharedInstance = GamificationData()

    /**
     Badges Displayed in BadgeCase. Order listed is Order Displayed

     */
    let badges : [Badges] = [
        Badges.init(type: .MailMaster , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", segue: .LinearBadge, displayName: NSLocalizedString("Mailmaster", comment:"Mailmaster badge" )),
        Badges.init(type: .SecureMailMaster , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", segue: .LinearBadge, displayName: NSLocalizedString("Secure Mailmaster", comment:"Secure Mailmaster badge" )),
        Badges.init(type: .onBoarding, pictureOff: "onboardingOff", pictureOn: "onboardingOn", segue: .LinearBadge, displayName: NSLocalizedString("Onboarded", comment:"Onboarded" )),
        Badges.init(type: .inviteAFriend, pictureOff: "invitefriendOff", pictureOn: "invitefriendOn", segue: .inviteFriend, displayName: NSLocalizedString("Invite a friend", comment: "Invite a friend" )),
        Badges.init(type: .Ambassador, pictureOff: "ambassadorOff", pictureOn: "ambassadorOn", segue: .inviteFriend, displayName: NSLocalizedString("Ambassador", comment:"Ambassador" ))
        ]
    /*
     old badges from pdf
     
     let badges : [Badges] = [
     Badges.init(type: .keyMaster, pictureOff: "keymasterOff", pictureOn: "keymasterOn", segue: .LinearBadge, displayName: NSLocalizedString("Keymaster", comment: "Keymaster")),
     Badges.init(type: .trustmaster, pictureOff: "trustmasterOff", pictureOn: "trustmasterOn", segue: .LinearBadge, displayName: NSLocalizedString("Trustmaster", comment: "Trustmaster")),
     Badges.init(type: .verschlüsselMaster, pictureOff: "verschluesselmasterOff", pictureOn: "verschluesselmasterOn", segue: .None, displayName: NSLocalizedString("Crypto Champion", comment: "Crypto Champion")),
     Badges.init(type: .firstMail, pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", segue: .LinearBadge, displayName: NSLocalizedString("First Encrypted Mail", comment:"First Encrypted Mail" )),
     Badges.init(type: .quizmaster, pictureOff: "quizmasterOff", pictureOn: "quizmasterOn", segue: .LinearBadge, displayName: NSLocalizedString("Quizmaster", comment: "Quizmaster")),
     Badges.init(type: .onBoarding, pictureOff: "onboardingOff", pictureOn: "onboardingOn", segue: .LinearBadge, displayName: NSLocalizedString("Onboarded", comment:"Onboarded" )),
     Badges.init(type: .inviteAFriend, pictureOff: "invitefriendOff", pictureOn: "invitefriendOn", segue: .inviteFriend, displayName: NSLocalizedString("Invite a friend", comment: "Invite a friend" )),
     Badges.init(type: .Ambassador, pictureOff: "ambassadorOff", pictureOn: "ambassadorOn", segue: .inviteFriend, displayName: NSLocalizedString("Ambassador", comment:"Ambassador" )),
     ]

     */



    // MARK:- Functions

    
    /**
     - Parameter badge: BadgeType identifying the Badge for which an Array is requested
     
     **Returns** an Array **type [Badges]** containing the subBadges or an empty Array in Case of Failure
     */
    func subBadgesforBadge(badge : BadgeType) -> [Badges] {

        switch badge {
        case .Ambassador :
            return [
                Badges(pictureOff: "ambassadorOff", pictureOn: "ambassadorOn", displayName: NSLocalizedString("Invite 1 friend successfully", comment: "Invite 1 friend" ), achievmentsNeeded: [.OneFriendInvited]),
                Badges(pictureOff: "ambassadorOff", pictureOn: "ambassadorOn", displayName: NSLocalizedString("Invite 4 more friends successfully", comment:"Invite 4 more friends" ), achievmentsNeeded: [.FiveFriendsInvited ]),
            ]
        case .inviteAFriend :
            return [Badges(pictureOff: "invitefriendOff", pictureOn: "invitefriendOn", displayName: NSLocalizedString("One friend successful invited", comment:"One friend invited" ), achievmentsNeeded: [.OneFriendInvited ])]
        case .keyMaster :
            return [
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Installed", comment: "Installed")),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Connect to KeyChain", comment:"Connect to KeyChain" )),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Create your Keys", comment: "Create your Keys")),
            ]
        case .onBoarding :
            return [
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Installed", comment:"Installed" )),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("My own Set of Keys", comment:"My own Set of Keys" )),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Sent first Encrypted Mail", comment: "Sent first Encrypted Mail"), achievmentsNeeded: [.SecureSend]),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Received first Encrypted Mail", comment: "Received first Encrypted Mail" ), achievmentsNeeded: [.SecureReceived] ),
              //  Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOff", displayName: NSLocalizedString("Onboarding Complete", comment: "Onboarding Complete" )),
            ]
        case .MailMaster:
            return [
                Badges.init(type: .MailMaster1 , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", displayName: NSLocalizedString("One Mail Send/Received", comment:"Mailmaster Subbadge" ), achievmentsNeeded: [.Mails1]),
                Badges.init(type: .MailMaster10 , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", displayName: NSLocalizedString("10 Mails Send/Received", comment:"Mailmaster Subbadge" ), achievmentsNeeded: [.Mails10]),
                Badges.init(type: .MailMaster50 , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", displayName: NSLocalizedString("50 Mails Send/Received", comment:"Mailmaster Subbadge" ), achievmentsNeeded: [.Mails50]),
                Badges.init(type: .MailMaster100 , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", displayName: NSLocalizedString("100 Mails Send/Received", comment:"Mailmaster Subbadge" ), achievmentsNeeded: [.Mails100]),
                Badges.init(type: .MailMaster1000 , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", displayName: NSLocalizedString("1000 Mails Send/Received", comment:"Mailmaster Subbadge" ), achievmentsNeeded: [.Mails1000])
            ]
        case .SecureMailMaster:
            return [
                Badges.init(type: .SecureMailMaster1 , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", displayName: NSLocalizedString("One secure Mail Send/Received", comment:"SecureMailMaster Subbadge" ), achievmentsNeeded: [.SecureMails1 ]),
                Badges.init(type: .SecureMailMaster10 , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", displayName: NSLocalizedString("10 secure Mails Send/Received", comment:"SecureMailMaster Subbadge" ), achievmentsNeeded: [.SecureMails10 ]),
                Badges.init(type: .SecureMailMaster50 , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", displayName: NSLocalizedString("50 secure Mails Send/Received", comment:"SecureMailMaster Subbadge" ), achievmentsNeeded: [.SecureMails50 ]),
                Badges.init(type: .SecureMailMaster100 , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", displayName: NSLocalizedString("100 secure Mails Send/Received", comment:"SecureMailMaster Subbadge" ), achievmentsNeeded: [.SecureMails100]),
                Badges.init(type: .SecureMailMaster1000 , pictureOff: "verschluesseltOff", pictureOn: "verschluesseltOn", displayName: NSLocalizedString("1000 secure Mails Send/Received", comment:"SecureMailMaster Subbadge" ), achievmentsNeeded: [.SecureMails1000])
            ]
        case .quizmaster :
            return [
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Quiz 1", comment:"Quiz 1" )),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Quiz 2", comment: "Quiz 2")),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Quiz 3", comment:"Quiz 3" )),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Quiz 4", comment: "Quiz 4")),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Quiz a friend", comment:"Quiz a friend" )),
            ]
        case .trustmaster :
            return [
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Trust one contacts Key", comment: "Trust one contacts Key")),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Send one encrypted Mail", comment:"Send one encrypted Mail" )),
            ]
        case .verschlüsselMaster :
            return [Badges]()
        case .firstMail :
            return [
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Installed", comment:"Installed" )),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Connect to Keychain", comment: "Connect to Keychain")),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Create your Keys", comment:"Create your Keys" )),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Add your friends publc Key", comment: "Add your friends publc Key")),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Sent first encrypted mail", comment: "Sent first encrypted mail")),
            ]



        default:
            return [Badges]()

        }

    }

    /**
     - Parameter badge: BadgeType identifying the Badge for which a Query is placed

     **Returns** the boolean Value whether the Badge is **Achieved (true)** or not (false)
     */
    func badgeAchieved(badge : Badges) -> Bool {
        // Check if Subbadges are Finished
        let subBadges = self.subBadgesforBadge(badge: badge.type)
        for element in subBadges {
            if !self.badgeAchieved(badge: element){
                return false
            }
        }

        //Check if Badge is Finished
        if badge.achievments != nil {
            for achievment in badge.achievments! {
                if !self.achievmentFinished(which: achievment) {
                    return false
                }
            }
        }

        return true


    }



    /**
     Checks Individual Achievments.
     */
    fileprivate func achievmentFinished(which : Achievment) -> Bool {
        let contacts: [EnzevalosContact] = DataHandler.handler.getContacts()
        //let contactCount = contacts.count

        var secureContactsCount : Int = 0

        var secureMailsReceived : Int = 0
        var secureMailsSend : Int = 0

        var mailsSend : Int = 0
        var mailsReceived : Int = 0

        for contact in contacts {
            if contact.hasKey { secureContactsCount += 1 }

            var mailsTo : [PersistentMail] = contact.to
            mailsTo.append(contentsOf: contact.cc)
            mailsTo.append(contentsOf: contact.bcc)

            let mailsFrom : [PersistentMail] = contact.from

            for mail in mailsTo {
                if mail.isSecure {
                    secureMailsSend += 1
                }else {
                    mailsSend += 1
                }
            }

            for mail in mailsFrom {
                if mail.isSecure {
                    secureMailsReceived += 1
                }else {
                    mailsReceived += 1
                }
            }

        }


        let mailsCount : Int = mailsSend + secureMailsSend + mailsReceived + secureMailsReceived
        let secureMailsCount : Int = secureMailsReceived + secureMailsSend




            switch which {
            case .Firstkey: return false
            case .OneFriendInvited:
                return secureContactsCount > 0
            case .FiveFriendsInvited:
                return secureContactsCount > 5
            case .Mails1:
                return mailsCount > 1
            case .Mails10:
                return mailsCount >= 10
            case .Mails50:
                return mailsCount >= 50
            case .Mails100:
                return mailsCount >= 100
            case .Mails1000:
                return mailsCount >= 1000
            case .SecureMails1:
                return secureMailsCount >= 1
            case .SecureMails10:
                return secureMailsCount >= 10
            case .SecureMails50:
                return secureMailsCount >= 50
            case .SecureMails100:
                return secureMailsCount >= 100
            case .SecureMails1000:
                return secureMailsCount >= 1000
            case .SecureSend:
                return secureMailsSend > 0
            case .SecureReceived:
                return secureMailsReceived > 0
           // default: return false
            }
    }
    /**
     
        return the Percentage of Secure Contacts and Secure Mails.
        **(SecureContacts : Float, SecureMails : Float)**
     */
    func getSecureProgress() -> (Float,Float) {
        let contacts: [EnzevalosContact] = DataHandler.handler.getContacts()
        //let contactCount = contacts.count

        var secureContactsCount : Int = 0

        var secureMailsReceived : Int = 0
        var secureMailsSend : Int = 0

        var mailsSend : Int = 0
        var mailsReceived : Int = 0

        for contact in contacts {
            if contact.hasKey { secureContactsCount += 1 }

            var mailsTo : [PersistentMail] = contact.to
            mailsTo.append(contentsOf: contact.cc)
            mailsTo.append(contentsOf: contact.bcc)

            let mailsFrom : [PersistentMail] = contact.from

            for mail in mailsTo {
                if mail.isSecure {
                    secureMailsSend += 1
                }else {
                    mailsSend += 1
                }
            }

            for mail in mailsFrom {
                if mail.isSecure {
                    secureMailsReceived += 1
                }else {
                    mailsReceived += 1
                }
            }

        }

        let mailsCount : Int = mailsSend + secureMailsSend + mailsReceived + secureMailsReceived
        let secureMailsCount : Int = secureMailsReceived + secureMailsSend
        let totalMails : Int = mailsCount + secureMailsCount
        return ( Float(secureContactsCount) / Float(contacts.count) , Float(secureMailsCount) / Float(totalMails) )
    }

}
