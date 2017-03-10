//
//  ReadViewController.swift
//  readView
//
//  Created by Joscha on 22.07.16.
//  Copyright © 2016 Joscha. All rights reserved.
//

import UIKit
import Foundation

class ReadViewController: UITableViewController {
    @IBOutlet weak var sender: UILabel!
    @IBOutlet weak var receivers: UILabel!
    @IBOutlet weak var receivedTime: UILabel!
    @IBOutlet weak var subject: UILabel!
    @IBOutlet weak var messageBody: UILabel!

    // Cells
    @IBOutlet weak var senderCell: UITableViewCell!
    @IBOutlet weak var receiversCell: UITableViewCell!
    @IBOutlet weak var subjectCell: UITableViewCell!
    @IBOutlet weak var infoCell: UITableViewCell!
    @IBOutlet weak var infoButtonCell: UITableViewCell!
    @IBOutlet weak var messageCell: MessageBodyTableViewCell!

    @IBOutlet weak var iconButton: UIButton!

    @IBOutlet weak var SeperatorConstraint: NSLayoutConstraint!

    var mail: Mail? = nil
    let troubleColor = ThemeManager.troubleMessageColor()
    let encryptColor = ThemeManager.encryptedMessageColor()
    let uncryptColor = ThemeManager.uncryptedMessageColor()


    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0

        // not possible to set in IB
        SeperatorConstraint.constant = 1 / UIScreen.mainScreen().scale
        infoCell.layoutMargins = UIEdgeInsetsZero

        setUItoMail()
    }

    override func viewWillAppear(animated: Bool) {
        // NavigationBar color
        if let m = mail {
            if m.trouble {
                self.navigationController?.navigationBar.barTintColor = self.troubleColor
            } else if m.isSecure {
                self.navigationController?.navigationBar.barTintColor = self.encryptColor
            } else {
                self.navigationController?.navigationBar.barTintColor = self.uncryptColor
            }
        }
    }

    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)

        if parent == nil {
            UIView.animateWithDuration(0.3, animations: { self.navigationController?.navigationBar.barTintColor = ThemeManager.defaultColor })
        }
    }

    // set top seperator height
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 8
        }
        return tableView.sectionHeaderHeight
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if mail != nil {
            if mail!.trouble && mail!.showMessage {
                return 3
            }
        }

        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        }
        if mail != nil {
            if mail!.trouble && section == 1 {
                if mail!.showMessage {
                    return 1
                } else {
                    return 2
                }
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
            if mail != nil {
                if mail!.trouble {
                    if indexPath.row == 0 {
                        return infoCell
                    } else if indexPath.row == 1 {
                        return infoButtonCell
                    }
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

            sender.text = m.from.address
            //let useraddr: String = UserManager.loadUserValue(Attribute.UserAddr) as! String
            if m.getReceivers().count == 1 && m.cc?.count > 0 { // && m.to!.first?.mail_address == useraddr  TODO: WHY?
                receivers.text = NSLocalizedString("Cc", comment: "Carbon Copy") + ": "
                if let cc = m.cc {
                    for c in cc {
                        receivers.text?.appendContentsOf(c.address)
                        receivers.text?.appendContentsOf(" ")
                    }
                }
            } else { //TODO: Fix all this by replacing it with VENTokenField
                receivers.text = NSLocalizedString("To", comment: "To label") + ": "
                for r in m.getReceivers() {
                    receivers.text?.appendContentsOf(r.address)
                    receivers.text?.appendContentsOf(" ")
                }
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
        }
    }
}
