//
//  MailObject.swift
//  readView
//
//  Created by Joscha on 22.07.16.
//  Copyright © 2016 Joscha. All rights reserved.
//

import Foundation

class Mail: Comparable {
    var sender: String?
    var receivers = [String]()
    let time: NSDate?
    let received: Bool
    var subject: String?
    var body: String?
    var isUnread = true
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
            switch mailTime.timeIntervalSinceNow {
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

    init(sender: String?, receivers: [String], time: NSDate?, received: Bool, subject: String?, body: String?, isEncrypted: Bool, isVerified: Bool, trouble: Bool) {
        self.sender = sender
        self.subject = subject
        self.receivers = receivers
        self.time = time
        self.received = received
        self.subject = subject
        self.body = body
        self.isEncrypted = isEncrypted
        self.isVerified = isVerified
        setTrouble(trouble)
    }
    
    func setTrouble(trouble: Bool) {
        self.trouble = trouble
    }
}

func ==(lhs: Mail, rhs: Mail) -> Bool {
    return lhs.time == rhs.time
}

func <(lhs: Mail, rhs: Mail) -> Bool {
    return lhs.time < rhs.time
}