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
    @IBOutlet weak var seperator: NSLayoutConstraint!
    @IBOutlet weak var seperator2: NSLayoutConstraint!
    
    @IBAction func firstButtonPressed(sender: AnyObject) {
        if let delegate = delegate where firstMail != nil {
            firstButton.backgroundColor = UIColor(red:0.85, green:0.85, blue:0.85, alpha:1.0)
            print("Open mail \(firstMail?.subject) | read status: \(firstMail?.isRead)")
            delegate.callSegueFromCell(firstMail)
        }
    }
    
    @IBAction func secondButtonPressed(sender: AnyObject) {
        if let delegate = delegate where secondMail != nil {
            secondButton.backgroundColor = UIColor(red:0.85, green:0.85, blue:0.85, alpha:1.0)
            delegate.callSegueFromCell(secondMail)
        }
    }
    
    @IBAction func moreButtonPressed(sender: AnyObject) {
        if let delegate = delegate {
            delegate.callSegueFromCell2(enzContact)
        }
    }
    
    @IBAction func contactButtonPressed(sender: AnyObject) {
        if let delegate = delegate {
            delegate.callSegueToContact(enzContact)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        firstButton.backgroundColor = UIColor.clearColor()
        secondButton.backgroundColor = UIColor.clearColor()
        firstButton.addTarget(self, action: .cellTouched, forControlEvents: [.TouchDown, .TouchDragEnter])
        firstButton.addTarget(self, action: .clearCell, forControlEvents: [.TouchUpOutside, .TouchDragExit, .TouchCancel])
        secondButton.addTarget(self, action: .cellTouched, forControlEvents: [.TouchDown, .TouchDragEnter])
        secondButton.addTarget(self, action: .clearCell, forControlEvents: [.TouchUpOutside, .TouchDragExit, .TouchCancel])
        seperator.constant = 1 / UIScreen.mainScreen().scale
        seperator2.constant = 1 / UIScreen.mainScreen().scale
    }
    
    var enzContact: KeyRecord? {
        didSet {
            if let con = enzContact {
                firstMail = con.getFromMails().first
                if con.getFromMails().count > 1 {
                    secondMail = con.getFromMails()[1]
                    secondButton.enabled = true
                } else {
                    secondDateLabel.text = ""
                    secondSubjectLabel.text = ""
                    secondMessageLabel.text = NSLocalizedString("NoFurtherMessages", comment: "There is only one message from this sender.")
                    secondButton.enabled = false
                }
                if con.isSecure {
                    iconView.image = IconsStyleKit.imageOfLetter
//                    iconView.image = UIImage(named: "letter_small_2")!
                } else {
                    iconView.image = IconsStyleKit.imageOfPostcard
//                    iconView.image = UIImage(named: "postcard_small")!
                }

                self.contact = con.getCNContact()
                nameLabel.text = con.name
                faceView.image = con.getImageOrDefault()
                faceView.layer.cornerRadius = faceView.frame.height / 2
                faceView.clipsToBounds = true
            }
        }
    }
    
    var firstMail: Mail? {
        didSet {
            if let mail = firstMail {
                if !mail.isRead {
                    firstSubjectLabel.font = UIFont.boldSystemFontOfSize(17.0)
                } else {
                    firstSubjectLabel.font = UIFont.systemFontOfSize(17.0)
                }
                
                firstSubjectLabel.text = mail.getSubjectWithFlagsString()
                
                // Reducing message to one line and truncating to 50
                var message: String = ""
                if mail.isEncrypted {
                    /*if mail.decryptedBody == nil {
                        mail.decryptIfPossible()
                    }*/
                    if mail.isEncrypted {
                        message = mail.getDecryptedMessage()
                    }
                }
                else if mail.body == nil {
                    message = mail.body!
                }
                if message.characters.count > 50 {
                    message = message.substringToIndex(message.startIndex.advancedBy(50))
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
                if !mail.isRead {
                    secondSubjectLabel.font = UIFont.boldSystemFontOfSize(17.0)
                } else {
                    secondSubjectLabel.font = UIFont.systemFontOfSize(17.0)
                }
                
                secondSubjectLabel.text = mail.getSubjectWithFlagsString()

                // Reducing message to one line and truncating to 50
                /*let message: String
                if mail.body?.characters.count > 50 {
                    message = mail.body!.substringToIndex(mail.body!.startIndex.advancedBy(50))
                } else {
                    message = mail.body!
                }*/
                var message: String = ""
                if mail.isEncrypted {
                    /*if mail.decryptedBody == nil {
                        mail.decryptIfPossible()
                    }*/
                    
                    if !mail.trouble{
                        message = mail.getDecryptedMessage()
                    }
                }
                else if mail.body != nil {
                    message = mail.body!
                }
                if message.characters.count > 50 {
                    message = message.substringToIndex(message.startIndex.advancedBy(50))
                }
                let messageArray = message.componentsSeparatedByString("\n")
                secondMessageLabel.text = messageArray.joinWithSeparator(" ")
                
                secondDateLabel.text = mail.timeString
                
                moreButton.enabled = true
            }
        }
    }
    
    var contact: CNContact?
    
    func cellTouched(sender: AnyObject) {
        if let button = sender as? UIButton {
            button.backgroundColor = UIColor(red:0.85, green:0.85, blue:0.85, alpha:1.0)
        }
    }
    
    func clearCell(sender: AnyObject) {
        if let button = sender as? UIButton {
            button.backgroundColor = UIColor.clearColor()
        }
    }
}

private extension Selector {
    static let cellTouched = #selector(InboxTableViewCell.cellTouched(_:))
    static let clearCell = #selector(InboxTableViewCell.clearCell(_:))
}
