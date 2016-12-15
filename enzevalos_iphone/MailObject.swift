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
    var decryptedBody: String? //TODO: bei der Serialisierung auf nil setzen
    var isVerified = false
    var isEncrypted = false
    var unableToDecrypt = false
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
        if self.subject == nil || (self.subject?.isEmpty)! {
            subj = NSLocalizedString("SubjectNo", comment: "This email has no subject")
        } else {
            subj = subject!
        }
        var returnString: String = ""
        if trouble {
            returnString.appendContentsOf("❗️ ")
        }
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
        return "\(returnString)\(subj)"
    }

    init(uid: UInt32, sender: MCOAddress?, receivers: [MCOAddress], cc: [MCOAddress], time: NSDate?, received: Bool, subject: String?, body: String?, decryptedBody: String?, isEncrypted: Bool, isVerified: Bool, trouble: Bool, isUnread: Bool, flags: MCOMessageFlag) {
        self.uid = uid
        self.sender = sender
        self.subject = subject
        self.receivers = receivers
        self.cc = cc
        self.time = time
        self.received = received
        self.subject = subject
        self.body = body
        self.decryptedBody = decryptedBody
        self.isUnread = isUnread
        self.flags = flags
        self.isEncrypted = isEncrypted
        self.isVerified = isVerified
        setTrouble(trouble)
    }
    
    func setTrouble(trouble: Bool) {
        self.trouble = trouble
    }
    
    func decryptIfPossible(){
        if body != nil {
            if self.isEncrypted {
                if KeyHandler.createHandler().getPrivateKey() == nil {
                    self.unableToDecrypt = true
                    return
                }
                if !CryptoHandler.getHandler().pgp.keys.contains((KeyHandler.createHandler().getPrivateKey()?.key)!) {
                    CryptoHandler.getHandler().pgp.keys.append((KeyHandler.createHandler().getPrivateKey()?.key)!)
                }
                do {
                    var signed : ObjCBool = false
                    var valid : ObjCBool = false
                    var integrityProtected : ObjCBool = false
                
                    var signatureKey : PGPKey? = nil
                    
                    if self.sender != nil && self.sender?.mailbox != nil {
                        if KeyHandler.createHandler().addrHasKey((self.sender?.mailbox)!) {
                            signatureKey = KeyHandler.createHandler().getKeyByAddr((self.sender?.mailbox)!)?.key
                        }
                    }
                
                //verifyWithPublicKey: KeyHandler.createHandler().getKeyByAddr(header.from.mailbox)?.key
                    
                    let decTrash = (try? CryptoHandler.getHandler().pgp.decryptData(body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected))
                    if decTrash != nil {
                        self.decryptedBody = String(data: decTrash!, encoding: NSUTF8StringEncoding)//String(data: (try? CryptoHandler.getHandler().pgp.decryptData(body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: signatureKey, signed: &signed, valid: &valid, integrityProtected: &integrityProtected))! as NSData, encoding: NSUTF8StringEncoding)
                        //print(String(data: (try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected), encoding: NSUTF8StringEncoding)))
                        self.isVerified = Bool(valid)
                        
                        print(" signed: ",signed," valid: ",valid, " integrityProtected: ",integrityProtected)
                        
                        if signatureKey != nil && !valid && signed {
                            self.trouble = true
                        }
                    }
                    
                    /*if (try? CryptoHandler.getHandler().pgp.decryptData(body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected) as NSData?) != nil && ((try? CryptoHandler.getHandler().pgp.decryptData(body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected))! as NSData?) != nil{
                    
                        self.decryptedBody = String(data: (try? CryptoHandler.getHandler().pgp.decryptData(body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: signatureKey, signed: &signed, valid: &valid, integrityProtected: &integrityProtected))! as NSData, encoding: NSUTF8StringEncoding)
                    //print(String(data: (try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected), encoding: NSUTF8StringEncoding)))
                        self.isVerified = Bool(valid)
                        
                        print(" signed: ",signed," valid: ",valid, " integrityProtected: ",integrityProtected)
                        
                        if signatureKey != nil && !valid && signed {
                            self.trouble = true
                        }
                    }*/
                //print(try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: nil, signed: &signed, valid: &valid, integrityProtected: &integrityProtected))
                //let content = try? CryptoHandler.getHandler().pgp.decryptData(body.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil)
                //print(content)
                } catch _ {
                
                    self.trouble = true
                    print("error while decrypting")
                }
            }
        }
    }
}

func ==(lhs: Mail, rhs: Mail) -> Bool {
    return lhs.time == rhs.time && lhs.uid == rhs.uid
}

func <(lhs: Mail, rhs: Mail) -> Bool {
    return lhs.time > rhs.time
}
