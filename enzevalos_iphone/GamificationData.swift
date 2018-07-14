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

        case .onBoarding :
            return [
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Installed", comment:"Installed" )),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("My own Set of Keys", comment:"My own Set of Keys" )),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Sent first Encrypted Mail", comment: "Sent first Encrypted Mail"), achievmentsNeeded: [.SecureSend]),
                Badges(pictureOff: "keymasterOff", pictureOn: "keymasterOn", displayName: NSLocalizedString("Received first Encrypted Mail", comment: "Received first Encrypted Mail" ), achievmentsNeeded: [.SecureReceived] ),
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
    
        default:
            return [Badges]()

        }

    }




  /**
    

     **Returns** the 3 last Achieved Badges
     */
    func get3LastAchieved() -> [Badges] {
        // check if new achieved
        for element in self.badges {
            _ = self.badgeAchieved(badge: element)
        }


        let key = UserManager.loadUserValue( Attribute.userAddr ) as! String

        let defaults = UserDefaults.standard

        let array = defaults.array(forKey: key)  as? [Int] ?? [Int]()

        var result = [Badges]()

        if array.count > 0 {
            for element in self.badges {
                if element.type.rawValue == array[0] {
                    result.append(element)
                }
            }
        }

        if array.count > 1 {
            for element in self.badges {
                if element.type.rawValue == array[1] {
                    result.append(element)
                }
            }
        }

        if array.count > 2 {
            for element in self.badges {
                if element.type.rawValue == array[2] {
                    result.append(element)
                }
            }
        }

        return result 

    }


    /**
     - Parameter badge: BadgeType identifying the Badge for which a Query is placed

     **Returns** the boolean Value whether the Badge is **Achieved (true)** or not (false)
     */
    func badgeAchieved(badge: Badges) -> Bool {
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



        // check if part of badges array
        for element in self.badges {
            if badge.type == element.type {

                let key = UserManager.loadUserValue( Attribute.userAddr ) as! String

                let defaults = UserDefaults.standard
                var array = defaults.array(forKey: key)  as? [Int] ?? [Int]()

                for zahl in array {
                    if zahl == badge.type.rawValue {
                        // bereits zuvor erreicht, exit
                        return true
                    }
                }


                array.insert(badge.type.rawValue , at: 0)
            //    NSLog("New Badge %@ achieved", badge.type)
                defaults.set(array, forKey: key)

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
                return invitations > 0
            case .FiveFriendsInvited:
                return invitations >= 5
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

        let a = contacts.count == 0 ? 0 : Float(secureContactsCount) / Float(contacts.count)
        let b = totalMails == 0 ? 0 : Float(secureMailsCount) / Float(totalMails)
        return ( a, b )
    }
    
    private var invitations: Int{
        get{
            var result = 0
            for adr in DataHandler.handler.getAddresses(){
                if let addr = adr as? Mail_Address{
                    if addr.invitations > 0{
                        result = result + 1
                    }
                }
            }
            return result
            
        }
    }

}
