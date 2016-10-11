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
    var cc = [MCOAddress]()
    let time: NSDate?
    let received: Bool
    let flags: MCOMessageFlag
    var subject: String?
    var body: String?
    var isVerified = false
    var isEncrypted = false
    var showMessage = true
    var isUnread: Bool {
        didSet{
            guard isUnread != oldValue else {
                return
            }
            if isUnread {
                AppDelegate.getAppDelegate().mailHandler.removeFlag(UInt64(self.uid), flags: MCOMessageFlag.Seen)
            } else {
                AppDelegate.getAppDelegate().mailHandler.addFlag(UInt64(self.uid), flags: flags.union(MCOMessageFlag.Seen))
            }
        }
    }

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
                returnString = NSLocalizedString("OneMinuteAgo", comment: "Email came one minute ago")
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
    
    var subjectWithFlagsString: String {
        let subj: String
        if self.subject == nil {
            subj = NSLocalizedString("SubjectNo", comment: "This email has no subject")
        } else {
            subj = subject!
        }
        var returnString: String = ""
        if isUnread {
            returnString.appendContentsOf("🔵 ")
        }
        if MCOMessageFlag.Answered.isSubsetOf(flags) {
            returnString.appendContentsOf("↩️ ")
        }
        if MCOMessageFlag.Forwarded.isSubsetOf(flags) {
            returnString.appendContentsOf("➡️ ")
        }
        if MCOMessageFlag.Flagged.isSubsetOf(flags) {
            returnString.appendContentsOf("⭐️ ")
        }
        let ret = "\(returnString)\(subj)"
        return ret
    }

    init(uid: UInt32, sender: MCOAddress?, receivers: [MCOAddress], cc: [MCOAddress], time: NSDate?, received: Bool, subject: String?, body: String?, isEncrypted: Bool, isVerified: Bool, trouble: Bool, isUnread: Bool, flags: MCOMessageFlag) {
        self.uid = uid
        self.sender = sender
        self.subject = subject
        self.receivers = receivers
        self.cc = cc
        self.time = time
        self.received = received
        self.subject = subject
        self.body = body
        self.isUnread = isUnread
        self.flags = flags
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
