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
    
    var showMessage:Bool{
        get{
            return self.showMessage
        }
        set{
            self.showMessage = newValue
        }
        
    }
    
    var isSecure: Bool{
        get{
            return isEncrypted && isSigned && !unableToDecrypt && !trouble
        }
    }
    
    var isRead: Bool{
        get{
            let value = getFlags().contains(MCOMessageFlag.Seen)
            return value
        }
        set {
            var flags: MCOMessageFlag
            flags = getFlags()
            if !newValue {
                flags.remove(MCOMessageFlag.Seen)
            } else {
                flags.insert(MCOMessageFlag.Seen)
            }
            setFlags(flags)
            DataHandler.getDataHandler().save()
        }
    }
    
    var timeString: String {
        var returnString = ""
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale.currentLocale()
        let mailTime = self.date
        let interval = NSDate().timeIntervalSinceDate(mailTime)
        switch interval {
            case -55..<55:
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
        return returnString
    }
    
    func addFrom(from: Mail_Address){
        self.from = from
    }
    
    func getFrom()->Mail_Address{
        return from
    }
    
    func addReceivers(receivers: [Mail_Address]){
        for ec in receivers{
            self.addToTo(ec)
        }
    }
    
    func getReceivers()->[Mail_Address]{
        var receivers = [Mail_Address] ()
        for obj in to{
            receivers.append(obj as! Mail_Address)
        }
        return receivers
    }

    
    //TODO: Optimize, only cast once
    
    func getCCs()->[Mail_Address]{
        var receivers = [Mail_Address] ()
        for obj in cc!{
            receivers.append(obj as! Mail_Address)
        }
        return receivers
    }
    
    func getBCCs()->[Mail_Address]{
        var receivers = [Mail_Address] ()
        for obj in bcc!{
            receivers.append(obj as! Mail_Address)
        }
        return receivers
    }
    
    func getFromAddress()->String{
        return (from.address)
    }
    
    func addCC(cc: [Mail_Address]){
        for ec in cc{
            self.addToCc(ec)
        }
    }
    
    func setFlags(flags: MCOMessageFlag){
        if flags.rawValue != Int(flag){
            AppDelegate.getAppDelegate().mailHandler.addFlag(self.uid.unsignedLongLongValue, flags: flags)
        }
       flag = Int32(flags.rawValue)

    }
    
    func getFlags()->MCOMessageFlag{
        return MCOMessageFlag.init(rawValue:Int(flag))
    }
    
    
    func changeTrouble(trouble: Bool){
            self.trouble = trouble
            showMessage = !trouble
    }
    
    
    
    func getDecryptedMessage()-> String{
        return body!
        
        /*
 func decryptIfPossible(){
 if body != nil {
 if self.isEncrypted {
 if KeyHandler.getHandler().getPrivateKey() == nil {
 self.unableToDecrypt = true
 return
 }
 if !CryptoHandler.getHandler().pgp.keys.contains((KeyHandler.getHandler().getPrivateKey()?.key)!) {
 CryptoHandler.getHandler().pgp.keys.append((KeyHandler.getHandler().getPrivateKey()?.key)!)
 }
 do {
 var signed : ObjCBool = false
 var valid : ObjCBool = false
 var integrityProtected : ObjCBool = false
 
 var signatureKey : PGPKey? = nil
 
 if self.sender != nil && self.sender?.mailbox != nil {
 if KeyHandler.getHandler().addrHasKey((self.sender?.mailbox)!) {
 signatureKey = KeyHandler.getHandler().getKeyByAddr((self.sender?.mailbox)!)?.key
 }
 }
 
 //verifyWithPublicKey: KeyHandler.createHandler().getKeyByAddr(header.from.mailbox)?.key
 
 let decTrash = (try? CryptoHandler.getHandler().pgp.decryptData(body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: signatureKey, signed: &signed, valid: &valid, integrityProtected: &integrityProtected))
 if decTrash != nil {
 self.decryptedBody = String(data: decTrash!, encoding: NSUTF8StringEncoding)//String(data: (try? CryptoHandler.getHandler().pgp.decryptData(body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: signatureKey, signed: &signed, valid: &valid, integrityProtected: &integrityProtected))! as NSData, encoding: NSUTF8StringEncoding)
 //print(String(data: (try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected), encoding: NSUTF8StringEncoding)))
 self.isVerified = Bool(valid)
 
 print(" signed: ",signed," valid: ",valid, " integrityProtected: ",integrityProtected)
 
 if signatureKey != nil && !valid && signed {
 self.trouble = true
 }
 }
 
 
 } catch _ {
 
 self.trouble = true
 print("error while decrypting")
 }
 }
 }
 }
*/
    }
    
    func getUID()->UInt64{
        return self.uid.unsignedLongLongValue
    }
    

    func getSubjectWithFlagsString()-> String{
        let subj: String
        let flags = getFlags()
        var returnString: String = ""

        if self.subject == nil || (self.subject?.isEmpty)! {
            subj = NSLocalizedString("SubjectNo", comment: "This email has no subject")
        } else {
            subj = subject!
        }
        if self.trouble {
            returnString.appendContentsOf("❗️ ")
        }
        if !self.isRead {
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
        return "\(returnString)\(subj)"
    }
    
}

public func ==(lhs: Mail, rhs: Mail) -> Bool {
    return lhs.date == rhs.date && lhs.uid == rhs.uid
}

public func <(lhs: Mail, rhs: Mail) -> Bool {
    return lhs.date > rhs.date
}

