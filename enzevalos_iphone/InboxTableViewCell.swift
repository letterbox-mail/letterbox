//
//  InboxTableViewCell.swift
//  readView
//
//  Created by Joscha on 29.08.16.
//  Copyright © 2016 Joscha. All rights reserved.
//

import UIKit
import Contacts

class InboxTableViewCell: UITableViewCell {
    var delegate: InboxCellDelegator?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var faceView: UIImageView!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var firstSubjectLabel: UILabel!
    @IBOutlet weak var firstMessageLabel: UILabel!
    @IBOutlet weak var firstDateLabel: UILabel!
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondSubjectLabel: UILabel!
    @IBOutlet weak var secondMessageLabel: UILabel!
    @IBOutlet weak var secondDateLabel: UILabel!
    @IBOutlet weak var secondButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    
    @IBAction func firstButtonPressed(sender: AnyObject) {
        if let delegate = delegate where firstMail != nil {
            enzContact?.mails.maxElement()?.isUnread = false
            delegate.callSegueFromCell(firstMail)
        }
    }
    
    @IBAction func secondButtonPressed(sender: AnyObject) {
        if let delegate = delegate where secondMail != nil{
            secondMail!.isUnread = false
            delegate.callSegueFromCell(secondMail)
        }
    }
    
    @IBAction func moreButtonPressed(sender: AnyObject) {
    }
    
    var enzContact: EnzevalosContact? {
        didSet {
            if let con = enzContact {
                self.firstMail = con.mails.last
                if con.mails.count > 1 {
                    self.secondMail = con.mails[con.mails.endIndex - 2]
                }
                self.contact = con.contact
            }
        }
    }
    
    var firstMail: Mail? {
        didSet {
            if let mail = firstMail {
                if mail.isUnread {
                    firstSubjectLabel.font = UIFont.boldSystemFontOfSize(17.0)
                } else {
                    firstSubjectLabel.font = UIFont.systemFontOfSize(17.0)
                }
                
                if let subj = mail.subject {
                    if subj != "" && subj != " " {
                        firstSubjectLabel.text = subj
                    } else {
                        firstSubjectLabel.text = "(Kein Betreff)"
                    }
                }
                
                // Reducing message to one line and truncating to 50
                let message: String
                if mail.body?.characters.count > 50 {
                    message = mail.body!.substringToIndex(mail.body!.startIndex.advancedBy(50))
                } else {
                    message = mail.body!
                }
                let messageArray = message.componentsSeparatedByString("\n")
                firstMessageLabel.text = messageArray.joinWithSeparator(" ")
                
                firstDateLabel.text = mail.timeString
            }
        }
    }
    
    var secondMail: Mail? {
        didSet {
            if let mail = secondMail {
                if mail.isUnread {
                    secondSubjectLabel.font = UIFont.boldSystemFontOfSize(17.0)
                } else {
                    secondSubjectLabel.font = UIFont.systemFontOfSize(17.0)
                }
                
                if let subj = mail.subject {
                    if subj != "" && subj != " " {
                        secondSubjectLabel.text = subj
                    } else {
                        secondSubjectLabel.text = "(Kein Betreff)"
                    }
                }
                
                // Reducing message to one line and truncating to 50
                let message: String
                if mail.body?.characters.count > 50 {
                    message = mail.body!.substringToIndex(mail.body!.startIndex.advancedBy(50))
                } else {
                    message = mail.body!
                }
                let messageArray = message.componentsSeparatedByString("\n")
                secondMessageLabel.text = messageArray.joinWithSeparator(" ")
               
                secondDateLabel.text = mail.timeString
                
                moreButton.enabled = true
            }
        }
    }
    
    var contact: CNContact? {
        didSet {
            if let con = contact {
                nameLabel.text = con.givenName + " " + con.familyName
                faceView.image = con.getImageOrDefault()
                faceView.layer.cornerRadius = faceView.frame.height / 2
                faceView.clipsToBounds = true
                if let m = firstMail {
                    if m.isEncrypted {
                        iconView.image = UIImage(named: "letter_small_2")!
                    } else {
                        iconView.image = UIImage(named: "postcard_small")!
                    }
                }
            }
        }
    }
}