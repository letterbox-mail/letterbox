//
//  MailObject.swift
//  readView
//
//  Created by Joscha on 22.07.16.
//  Copyright © 2016 Joscha. All rights reserved.
//

import Foundation

class Mail: Comparable {
    let uid: UInt32
    var sender: MCOAddress?
    var receivers = [MCOAddress]()
    let time: NSDate?
    let received: Bool
    var subject: String?
    var body: String?
    var isUnread: Bool
    var isVerified = false
    var isEncrypted = false
    var showMessage = true
    var trouble = true {
        didSet{
            if trouble {
                showMessage = false
            } else {
                showMessage = true
            }
        }
    }
    var timeString: String {
        var returnString = ""
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale.currentLocale()
        if let mailTime = self.time {
            let interval = NSDate().timeIntervalSinceDate(mailTime)
            switch interval {
            case -1..<55:
                returnString = NSLocalizedString("Now", comment: "New email")
            case 55..<120:
                returnString = NSLocalizedString("OneMinuteAgo", comment: "Email came one minute ago.")
            case 120..<24*60*60:
                dateFormatter.timeStyle = .ShortStyle
                returnString = dateFormatter.stringFromDate(mailTime)
            case 24*60*60..<48*60*60:
                returnString = NSLocalizedString("Yesterday", comment: "Email came yesterday")
            case 48*60*60..<72*60*60:
                returnString = NSLocalizedString("TwoDaysAgo", comment: "Email came two days ago")
            default:
                dateFormatter.dateStyle = .ShortStyle
                returnString = dateFormatter.stringFromDate(mailTime)
            }
        }
        return returnString
    }

    init(uid: UInt32, sender: MCOAddress?, receivers: [MCOAddress], time: NSDate?, received: Bool, subject: String?, body: String?, isEncrypted: Bool, isVerified: Bool, trouble: Bool, isUnread: Bool) {
        self.uid = uid
        self.sender = sender
        self.subject = subject
        self.receivers = receivers
        self.time = time
        self.received = received
        self.subject = subject
        self.body = body
        self.isUnread = isUnread
        self.isEncrypted = isEncrypted
        self.isVerified = isVerified
        setTrouble(trouble)
    }
    
    func setTrouble(trouble: Bool) {
        self.trouble = trouble
    }
}

func ==(lhs: Mail, rhs: Mail) -> Bool {
    return lhs.time == rhs.time && lhs.uid == rhs.uid
}

func <(lhs: Mail, rhs: Mail) -> Bool {
    return lhs.time > rhs.time
}
