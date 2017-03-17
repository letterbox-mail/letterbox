//
//  ReadViewController.swift
//  readView
//
//  Created by Joscha on 22.07.16.
//  Copyright © 2016 Joscha. All rights reserved.
//

import UIKit
import Foundation
import VENTokenField

class ReadViewController: UITableViewController {

    @IBOutlet weak var senderTokenField: VENTokenField!
    @IBOutlet weak var toTokenField: VENTokenField!
    @IBOutlet weak var receivedTime: UILabel!
    @IBOutlet weak var subject: UILabel!
    @IBOutlet weak var messageBody: UILabel!
    @IBOutlet weak var infoHeadline: UILabel!
    @IBOutlet weak var infoText: UILabel!
    @IBOutlet weak var infoSymbol: UILabel!

    // Cells
    @IBOutlet weak var senderCell: UITableViewCell!
    @IBOutlet weak var receiversCell: UITableViewCell!
    @IBOutlet weak var subjectCell: UITableViewCell!
    @IBOutlet weak var infoCell: UITableViewCell!
    @IBOutlet weak var infoButtonCell: UITableViewCell!
    @IBOutlet weak var messageCell: MessageBodyTableViewCell!

    @IBOutlet weak var iconButton: UIButton!

    @IBOutlet weak var SeperatorConstraint: NSLayoutConstraint!

    var VENDelegate: ReadVENDelegate?

    var mail: Mail? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0

        VENDelegate = ReadVENDelegate(tappedWhenSelectedFunc: self.showContact, tableView: tableView)

        senderTokenField.delegate = VENDelegate
        senderTokenField.dataSource = VENDelegate
        senderTokenField.toLabelText = "\(NSLocalizedString("From", comment: "From field")):"
        senderTokenField.toLabelTextColor = UIColor.darkGrayColor()
        senderTokenField.readOnly = true

        toTokenField.delegate = VENDelegate
        toTokenField.dataSource = VENDelegate
        toTokenField.toLabelText = "\(NSLocalizedString("To", comment: "To field")):"
        toTokenField.toLabelTextColor = UIColor.darkGrayColor()
        toTokenField.setColorScheme(self.view.tintColor)
        toTokenField.readOnly = true

        // not possible to set in IB
        SeperatorConstraint.constant = 1 / UIScreen.mainScreen().scale
        infoCell.layoutMargins = UIEdgeInsetsZero

        setUItoMail()
    }

    override func viewWillAppear(animated: Bool) {
        // NavigationBar color
        if let mail = mail {
            if mail.trouble {
                self.navigationController?.navigationBar.barTintColor = ThemeManager.troubleMessageColor()
            } else if mail.isSecure {
                self.navigationController?.navigationBar.barTintColor = ThemeManager.encryptedMessageColor()
            } else {
                self.navigationController?.navigationBar.barTintColor = ThemeManager.uncryptedMessageColor()
            }
        }
    }

    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)

        if parent == nil {
            UIView.animateWithDuration(0.3, animations: { self.navigationController?.navigationBar.barTintColor = ThemeManager.defaultColor })
        }
    }

    func showContact(email: String) {
        let records = DataHandler.handler.getContactByAddress(email).records
        for r in records {
            for address in r.addresses {
                if address.mailAddress == email && address.prefEnc == r.hasKey {
                    performSegueWithIdentifier("showContact", sender: ["record": r, "email": email])
                    return
                }
            }
        }

//        performSegueWithIdentifier("showContact", sender: Record(email: email))
    }

    // set top seperator height
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 8
        }
        return tableView.sectionHeaderHeight
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 1 {
            if toTokenField.frame.height < 60 {
                return 44.0
            }
            return toTokenField.frame.height
        }
        return UITableViewAutomaticDimension
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let mail = mail {
            if mail.trouble || !mail.isSecure && mail.from.contact.hasKey {
                return 3
            }
        }

        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        }
        if let mail = mail {
            if section == 1 && mail.trouble && !mail.showMessage {
                return 2
            }
        }

        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                return senderCell
            case 1:
                return receiversCell
            default:
                return subjectCell
            }
        }
        if indexPath.section == 1 {
            if let mail = mail {
                if mail.trouble {
                    if indexPath.row == 0 {
                        return infoCell
                    } else if indexPath.row == 1 {
                        return infoButtonCell
                    }
                } else if mail.from.hasKey && !mail.isSecure {
                    infoSymbol.text = "?"
                    infoSymbol.textColor = ThemeManager.uncryptedMessageColor()
                    infoHeadline.text = NSLocalizedString("encryptedBeforeHeadline", comment: "The sender has encrypted before")
                    infoHeadline.textColor = UIColor.grayColor()
                    infoText.text = NSLocalizedString("encryptedBeforeText", comment: "The sender has encrypted before")
                    return infoCell
                }
            } else {
                return messageCell
            }
        }

        return messageCell
    }

    @IBAction func showEmailButton(sender: UIButton) {
        mail!.showMessage = true

        self.tableView.beginUpdates()
        let path = NSIndexPath(forRow: 1, inSection: 1)
        self.tableView.deleteRowsAtIndexPaths([path], withRowAnimation: .Fade)
        self.tableView.insertSections(NSIndexSet(index: 2), withRowAnimation: .Fade)
        self.tableView.endUpdates()
    }

    @IBAction func ignoreEmailButton(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func markUnreadButton(sender: AnyObject) {
        mail?.isRead = false
        navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func deleteButton(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func iconButton(sender: AnyObject) {
        if let m = mail {
            let alert: UIAlertController
            let url: String
            if m.trouble {
                alert = UIAlertController(title: NSLocalizedString("LetterDamaged", comment: "Modified email received")/*"Angerissener Brief"*/, message: NSLocalizedString("ReceiveDamagedInfo", comment: "Modefied email infotext"), preferredStyle: .Alert)
                url = "https://enzevalos.de/infos/corrupted"
            } else if m.isSecure {
                alert = UIAlertController(title: NSLocalizedString("Letter", comment: "letter label"), message: NSLocalizedString("ReceiveSecureInfo", comment: "Letter infotext"), preferredStyle: .Alert)
                url = "https://enzevalos.de/infos/letter"
            } else if m.isCorrectlySigned {
                alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "postcard label"), message: NSLocalizedString("ReceiveInsecureInfoVerified", comment: "Postcard infotext"), preferredStyle: .Alert)
                url = "https://enzevalos.de/infos/postcard_verified"
            } else if m.isEncrypted && !m.unableToDecrypt {
                alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "postcard label"), message: NSLocalizedString("ReceiveInsecureInfoEncrypted", comment: "Postcard infotext"), preferredStyle: .Alert)
                url = "https://enzevalos.de/infos/postcard_encrypted"
            } else if m.isEncrypted && m.unableToDecrypt {
                alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "postcard label"), message: NSLocalizedString("ReceiveInsecureInfoDecryptionFailed", comment: "Postcard infotext"), preferredStyle: .Alert)
                url = "https://enzevalos.de/infos/postcard_decryption_failed"
            } else {
                alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "postcard label"), message: NSLocalizedString("ReceiveInsecureInfo", comment: "Postcard infotext"), preferredStyle: .Alert)
                url = "https://enzevalos.de/infos/postcard"
            }
            alert.addAction(UIAlertAction(title: "Mehr Informationen", style: .Default, handler: { (action: UIAlertAction!) -> Void in UIApplication.sharedApplication().openURL(NSURL(string: url)!) }))
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(alert, animated: true, completion: nil)
            })
        }
    }

    func setUItoMail() {
        if let m = mail {

            // mark mail as read if viewcontroller is open for more than 1.5 sec
            let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC)))
            dispatch_after(delay, dispatch_get_main_queue()) {
                if let viewControllers = self.navigationController?.viewControllers {
                    for viewController in viewControllers {
                        if viewController.isKindOfClass(ReadViewController) {
                            m.isRead = true
                        }
                    }
                }
            }

            senderTokenField.delegate?.tokenField!(senderTokenField, didEnterText: m.from.contact.displayname!, mail: m.from.address)

            for receiver in m.getReceivers() {
                if let displayname = receiver.contact.displayname {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: displayname, mail: receiver.address)
                } else {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: receiver.address, mail: receiver.address)
                }
            }

            for receiver in m.getCCs() {
                if let displayname = receiver.contact.displayname {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: displayname, mail: receiver.address)
                } else {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: receiver.address, mail: receiver.address)
                }
            }

            for receiver in m.getBCCs() {
                if let displayname = receiver.contact.displayname {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: displayname, mail: receiver.address)
                } else {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: receiver.address, mail: receiver.address)
                }
            }

            if toTokenField.frame.height > 60 {
                toTokenField.collapse()
            }

            receivedTime.text = m.timeString

            if let subj = m.subject {
                if subj.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).characters.count > 0 {
                    subject.text = subj
                } else {
                    subject.text = NSLocalizedString("SubjectNo", comment: "This mail has no subject")
                }
            }

            //print("-----".commonPrefixWithString(m.body!, options: NSStringCompareOptions.CaseInsensitiveSearch))

            //in-line PGP
            if m.isEncrypted && !m.unableToDecrypt {
                //CryptoHandler.getHandler().pgp.keys.append((KeyHandler.createHandler().getPrivateKey()?.key)!)

                //let content = try? CryptoHandler.getHandler().pgp.decryptData(m.body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil)
                //print("read")
                //print(String(data: content!, encoding: NSUTF8StringEncoding))

                //var signed : ObjCBool = false
                //var valid : ObjCBool = false
                //var integrityProtected : ObjCBool = false

                //print(m.sender?.mailbox)
                //let decBody = try? CryptoHandler.getHandler().pgp.decryptData(m.body!.dataUsingEncoding(NSUTF8StringEncoding)!, passphrase: nil, verifyWithPublicKey: KeyHandler.createHandler().getKeyByAddr((m.sender?.mailbox)!)!.key, signed: &signed, valid: &valid, integrityProtected: &integrityProtected)

                //if decBody != nil {
                //    messageBody.text = String(data: decBody!, encoding: NSUTF8StringEncoding)
                //}

                //print("signed: ", signed, " valid: ", valid, " integrityProtected: ", integrityProtected)

                messageBody.text = m.decryptedBody
                //print(m.decryptedMessage)
                // if KeyHandler.getHandler().addrHasKey((m.from.address)) {

                //AFTERMERGE
                /*if m.from.hasKey{
                    let signatureKey = KeyHandler.getHandler().getKeyByAddr((m.from.address))?.key
                    print(signatureKey)
                }*/

            }
                else {
                messageBody.text = m.body
            }
            // NavigationBar Icon
            let iconView = UIImageView()
            iconView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
            iconView.contentMode = .ScaleAspectFit
            var icon: UIImage
            if m.trouble {
                icon = IconsStyleKit.imageOfLetterCorrupted
            } else if m.isSecure {
                icon = IconsStyleKit.imageOfLetterOpen
            } else {
                icon = IconsStyleKit.imageOfPostcard
            }
            iconView.image = icon
            iconButton.setImage(icon, forState: UIControlState.Normal)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "answerTo" {
            let navigationController = segue.destinationViewController as? UINavigationController
            let controller = navigationController?.topViewController as? SendViewController
            if controller != nil {
                controller?.answerTo = mail
            }
        } else if segue.identifier == "showContact" {
            let destinationVC = segue.destinationViewController as! ContactViewController
            if let sender = sender {
                destinationVC.contact = (sender["record"] as! KeyRecord)
                destinationVC.highlightEmail = (sender["email"] as! String)
            }
        }
    }
}
