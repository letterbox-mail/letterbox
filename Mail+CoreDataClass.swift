//
//  Mail+CoreDataClass.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 27/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//  This file was automatically generated and should not be edited.
//


import Foundation
import CoreData

@objc(Mail)
public class Mail: NSManagedObject, Comparable {
    
    
    var showMessage = false //TODO: Fix Me
    
    var timeString: String {
        var returnString = ""
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale.currentLocale()
        if let mailTime = self.date {
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
    
    func addFrom(from: EnzevalosContact){
        self.from = from
    }
    
    func getFrom()->EnzevalosContact{
        return from!
    }
    
    func addReceivers(receivers: [EnzevalosContact]){
        for ec in receivers{
            self.addToTo(ec)
        }
    }
    
    func getReceivers()->[EnzevalosContact]{
        var receivers = [EnzevalosContact] ()
        if to != nil{
            for obj in to!{
                receivers.append(obj as! EnzevalosContact)
            }
        }
        return receivers
    }
    
    //TODO: Optimize, only cast once
    
    func getCCs()->[EnzevalosContact]{
        var receivers = [EnzevalosContact] ()
        if to != nil{
            for obj in cc!{
                receivers.append(obj as! EnzevalosContact)
            }
        }
        return receivers
    }
    
    func getBCCs()->[EnzevalosContact]{
        var receivers = [EnzevalosContact] ()
        if to != nil{
            for obj in bcc!{
                receivers.append(obj as! EnzevalosContact)
            }
        }
        return receivers
    }
    
    func getFromAddress()->String{
        return (from?.mail_address)!
    }
    
    func addCC(cc: [EnzevalosContact]){
        for ec in cc{
            self.addToCc(ec)
        }
    }
    
    func setFlags(flags: MCOMessageFlag){
        flag = 0 //TODO FIx Me
    }
    
    
    //TODO FIX US
    func isUnread()->Bool{
        return true
    }
    
    func getDecryptedMessage()-> String{
        return body!
    }
    
    func getSubjectWithFlagsString()-> String{
        return subject!
    }
    
}

public func ==(lhs: Mail, rhs: Mail) -> Bool {
    return lhs.date == rhs.date && lhs.uid == rhs.uid
}

public func <(lhs: Mail, rhs: Mail) -> Bool {
    return lhs.date > rhs.date
}

