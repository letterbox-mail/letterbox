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
        dateFormatter.locale = NSLocale(localeIdentifier: "de_DE")
        if let mailTime = self.time {
            let interval = NSDate().timeIntervalSinceDate(mailTime)
            switch interval {
            case -1..<55:
                returnString = "jetzt"
            case 55..<120:
                returnString = "vor 1 min"
            case 120..<24*60*60:
                dateFormatter.timeStyle = .ShortStyle
                returnString = dateFormatter.stringFromDate(mailTime)
            case 24*60*60..<48*60*60:
                returnString = "Gestern"
            case 48*60*60..<72*60*60:
                returnString = "Vorgestern"
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
    return lhs.time < rhs.time
}
