//
//  ReadViewController.swift
//  readView
//
//  Created by Joscha on 22.07.16.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import UIKit
import Foundation
import VENTokenField

class ReadViewController: UITableViewController {

    @IBOutlet weak var senderTokenField: VENTokenField!
    @IBOutlet weak var toTokenField: VENTokenField!
    @IBOutlet weak var receivedTime: UILabel!
    @IBOutlet weak var subject: UILabel!
    @IBOutlet weak var infoHeadline: UILabel!
    @IBOutlet weak var infoText: UILabel!
    @IBOutlet weak var infoSymbol: UILabel!
    @IBOutlet weak var reactButton: UIButton!
    @IBOutlet weak var answerButton: UIBarButtonItem!
    @IBOutlet weak var messageBody: UITextView!
    @IBOutlet weak var iconButton: UIButton!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var archiveButton: UIBarButtonItem!
    @IBOutlet weak var SeperatorConstraint: NSLayoutConstraint!

    // Cells
    @IBOutlet weak var senderCell: UITableViewCell!
    @IBOutlet weak var receiversCell: UITableViewCell!
    @IBOutlet weak var subjectCell: UITableViewCell!
    @IBOutlet weak var infoCell: UITableViewCell!
    @IBOutlet weak var infoButtonCell: UITableViewCell!
    @IBOutlet weak var infoReactButtonCell: UITableViewCell!
    @IBOutlet weak var messageCell: MessageBodyTableViewCell!

    var VENDelegate: ReadVENDelegate?
    var textDelegate: ReadTextDelegate?

    var mail: PersistentMail? = nil

    var isDraft = false
    var isInSentFolder = false
    var isInArchiveFolder = false
    var isTrash = false
    var keyDiscoveryDate: Date? = nil
    
    var secretKeyPasswordField: UITextField? = nil

    var isNewPubKey: Bool? {
        guard let mail = mail, let signedKey = mail.signedKey else {
            return nil
        }

        if signedKey.counterSignedMails < 2 && mail.from.publicKeys.count > 1 {
            return true
        }
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0

        if let folder = mail?.folder {
            if folder.path.hasPrefix(UserManager.backendDraftFolderPath) {
                isDraft = true
            } else if folder.path.hasPrefix(UserManager.backendSentFolderPath) {
                isInSentFolder = true
            } else if folder.path.hasPrefix(UserManager.backendArchiveFolderPath) {
                isInArchiveFolder = true
            } else if folder.path.hasPrefix(UserManager.backendTrashFolderPath) {
                isTrash = true
            }
        }

        if isDraft {
            answerButton.title = NSLocalizedString("edit", comment: "")
        } else {
            answerButton.title = NSLocalizedString("answer", comment: "")
        }

        if isDraft || isInArchiveFolder || isTrash {
            archiveButton.isEnabled = false
        }

        if Logger.logging, let mail = self.mail {
            var message = "none"
            if showInfoSection(mail: mail) {
                if mail.trouble {
                    message = "corrupted"
                } else if mail.isEncrypted && mail.unableToDecrypt {
                    message = "couldNotDecrypt"
                } else if mail.from.hasKey && !mail.isSecure {
                    message = "encryptedBefore"
                }
            }
            Logger.log(readViewOpen: mail, message: message, draft: isDraft)
        }

        VENDelegate = ReadVENDelegate(tappedWhenSelectedFunc: { [weak self] in self?.showContact($0) }, tableView: tableView)

        senderTokenField.delegate = VENDelegate
        senderTokenField.dataSource = VENDelegate
        senderTokenField.toLabelText = "\(NSLocalizedString("From", comment: "From field")):"
        senderTokenField.toLabelTextColor = UIColor.darkGray
        senderTokenField.readOnly = true

        toTokenField.delegate = VENDelegate
        toTokenField.dataSource = VENDelegate
        toTokenField.toLabelText = "\(NSLocalizedString("To", comment: "To field")):"
        toTokenField.toLabelTextColor = UIColor.darkGray
        toTokenField.setColorScheme(self.view.tintColor)
        toTokenField.readOnly = true

        // not possible to set in IB
        SeperatorConstraint.constant = 1 / UIScreen.main.scale
        infoCell.layoutMargins = UIEdgeInsets.zero

        reactButton.setTitle(NSLocalizedString("reactButton", comment: "Title of the reaction Button"), for: .normal)

        setUItoMail()

        if let mail = mail, mail.folder.uidvalidity != mail.uidvalidity || !mail.received {
            deleteButton.isEnabled = false
        }

        textDelegate = ReadTextDelegate()
        textDelegate?.callback = { [weak self] (address: String) in self?.newMailCallback(Address: address) }

        messageBody.delegate = textDelegate

        self.keyDiscoveryDate = mail?.from.contact?.firstSecureMailReceived
    }

    deinit {
        print("===============|| ReadViewController deinitialized ||===============")

        if Logger.logging, let mail = self.mail {
            var message = "none"
            if mail.trouble && mail.showMessage || !mail.trouble && !mail.isSecure && mail.from.contact!.hasKey && mail.date > self.keyDiscoveryDate ?? Date() || !mail.trouble && mail.isEncrypted && mail.unableToDecrypt, !(UserDefaults.standard.value(forKey: "hideWarnings") as? Bool ?? false) {
                if mail.trouble {
                    message = "corrupted"
                } else if mail.isEncrypted && mail.unableToDecrypt {
                    message = "couldNotDecrypt"
                } else if mail.from.hasKey && !mail.isSecure {
                    message = "encryptedBefore"
                }
            }
            Logger.log(readViewClose: message, draft: isDraft)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        // NavigationBar color
        if let mail = mail {
            if mail.trouble {
                self.navigationController?.navigationBar.barTintColor = ThemeManager.troubleMessageColor()
                if !mail.showMessage {
                    answerButton.isEnabled = false
                }
            } else if mail.isSecure {
                self.navigationController?.navigationBar.barTintColor = ThemeManager.encryptedMessageColor()
            } else {
                self.navigationController?.navigationBar.barTintColor = ThemeManager.unencryptedMessageColor()
            }
        }
    }

    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)

        if parent == nil {
            UIView.animate(withDuration: 0.3, animations: { self.navigationController?.navigationBar.barTintColor = ThemeManager.defaultColor })
        }
    }

    func showContact(_ email: String) {
        let records = DataHandler.handler.getContactByAddress(email).records
        for r in records {
            for address in r.addresses {
                if address.mailAddress == email && address.hasKey == r.hasKey {
                    performSegue(withIdentifier: "showContact", sender: ["record": r, "email": email])
                    return
                }
            }
        }
    }

    /// Bool indicating whether a info section is shown with the exception of trouble mails where the message is not shown (because we need only 2 sections in that case)
    func showInfoSection(mail: PersistentMail) -> Bool {
        return (mail.trouble && mail.showMessage) || (!mail.trouble && !mail.isSecure && mail.from.hasKey && mail.date > keyDiscoveryDate ?? Date() && !isDraft && !isInSentFolder) || (!mail.trouble && mail.isEncrypted && mail.unableToDecrypt) || isNewPubKey ?? false && !(UserDefaults.standard.value(forKey: "hideWarnings") as? Bool ?? false)
    }

    func showInfoButton(mail: PersistentMail) -> Bool {
        return (mail.trouble && !mail.showMessage || mail.from.hasKey && !mail.isSecure && mail.date > keyDiscoveryDate ?? Date() && !mail.showMessage && !isDraft && !isInSentFolder) && !(UserDefaults.standard.value(forKey: "hideWarnings") as? Bool ?? false) && !mail.unableToDecrypt
    }

    // set top seperator height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 8
        }
        return tableView.sectionHeaderHeight
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 1 {
            if toTokenField.frame.height < 60 {
                return 44.0
            }
            return toTokenField.frame.height
        }
        return UITableViewAutomaticDimension
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let mail = mail, showInfoSection(mail: mail) {
            return 3
        }

        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        }

        if section == 1, let mail = mail, showInfoButton(mail: mail) {
            return 2
        }

        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        if let mail = mail, indexPath.section == 1 && !(UserDefaults.standard.value(forKey: "hideWarnings") as? Bool ?? false) && showInfoSection(mail: mail) {
            if indexPath.row == 0 {
                return infoCell
            } else if indexPath.row == 1 {
                if mail.trouble { // Show info reaction cell with one button
                    return infoButtonCell
                } else if mail.from.hasKey && !mail.isSecure && mail.date > (keyDiscoveryDate ?? Date()) && !isDraft { // Show info reaction cell with two buttons
                    return infoReactButtonCell
                }
            }
        }

        return messageCell
    }

    @IBAction func showEmailButton(_ sender: UIButton) {
        Logger.log(showBroken: self.mail)

        mail?.showMessage = true

        self.tableView.beginUpdates()
        let path = IndexPath(row: 1, section: 1)
        self.tableView.deleteRows(at: [path], with: .fade)
        self.tableView.insertSections(IndexSet(integer: 2), with: .fade)
        self.tableView.endUpdates()

        answerButton.isEnabled = true
    }

    @IBAction func ignoreEmailButton(_ sender: AnyObject) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func reactButton(_ sender: Any) {
        performSegue(withIdentifier: "answerTo", sender: "reactButton")
        Logger.log(reactTo: mail)
    }

    @IBAction func markUnreadButton(_ sender: AnyObject) {
        mail?.isRead = false
        navigationController?.popViewController(animated: true)
    }

    @IBAction func deleteButton(_ sender: AnyObject) {
        if let mail = mail {
            if isTrash {
                Logger.log(delete: mail, toTrash: false)
                AppDelegate.getAppDelegate().mailHandler.setFlag(mail.uid, flags: MCOMessageFlag.deleted, folder: mail.folder.path)
            } else {
                Logger.log(delete: mail, toTrash: true)
                AppDelegate.getAppDelegate().mailHandler.move(mails: [mail], from: mail.folder.path, to: UserManager.backendTrashFolderPath)
            }
        }
        navigationController?.popViewController(animated: true)
    }

    @IBAction func archiveButton(_ sender: AnyObject) {
        if let mail = mail {
            Logger.log(archive: mail)
            AppDelegate.getAppDelegate().mailHandler.move(mails: [mail], from: mail.folder.path, to: UserManager.backendArchiveFolderPath)
        }
        navigationController?.popViewController(animated: true)
    }

    @IBAction func iconButton(_ sender: AnyObject) {
        if let m = mail {
            let alert: UIAlertController
            let url: String
            if m.trouble {
                alert = UIAlertController(title: NSLocalizedString("LetterDamaged", comment: "Modified email received")/*"Angerissener Brief"*/, message: NSLocalizedString("ReceiveDamagedInfo", comment: "Modefied email infotext"), preferredStyle: .alert)
                url = "https://userpage.fu-berlin.de/letterbox/faq.html#collapseTorn"
            } else if m.isSecure {
                alert = UIAlertController(title: NSLocalizedString("Letter", comment: "letter label"), message: NSLocalizedString("ReceiveSecureInfo", comment: "Letter infotext"), preferredStyle: .alert)
                url = "https://userpage.fu-berlin.de/letterbox/faq.html#secureMailAnswer"
                alert.addAction(UIAlertAction(title: NSLocalizedString("ReadMailOnOtherDevice", comment: "email is not readable on other devices"), style: .default, handler: { (action: UIAlertAction!) -> Void in
                        Logger.log(close: url, mail: m, action: "exportKey")
                        self.performSegue(withIdentifier: "exportKeyFromReadView", sender: nil)
                    }))
            } else if m.isCorrectlySigned {
                alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "postcard label"), message: NSLocalizedString("ReceiveInsecureInfoVerified", comment: "Postcard infotext"), preferredStyle: .alert)
                url = "https://userpage.fu-berlin.de/letterbox/faq.html#collapsePostcard"
            } else if m.isEncrypted && !m.unableToDecrypt {
                alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "postcard label"), message: NSLocalizedString("ReceiveInsecureInfoEncrypted", comment: "Postcard infotext"), preferredStyle: .alert)
                url = "https://userpage.fu-berlin.de/letterbox/faq.html#collapsePostcard"
            } else if m.isEncrypted && m.unableToDecrypt {
                alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "postcard label"), message: NSLocalizedString("ReceiveInsecureInfoDecryptionFailed", comment: "Postcard infotext"), preferredStyle: .alert)
                url = "https://userpage.fu-berlin.de/letterbox/faq.html#collapseBeginPGP"
            } else {
                alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "postcard label"), message: NSLocalizedString("ReceiveInsecureInfo", comment: "Postcard infotext"), preferredStyle: .alert)
                url = "https://userpage.fu-berlin.de/letterbox/faq.html#collapsePostcard"
            }
            Logger.log(open: url, mail: m)
            alert.addAction(UIAlertAction(title: NSLocalizedString("MoreInformation", comment: "More Information label"), style: .default, handler: { (action: UIAlertAction!) -> Void in
                    Logger.log(close: url, mail: m, action: "openURL")
                    UIApplication.shared.openURL(URL(string: url)!)
                }))
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) -> Void in
                Logger.log(close: url, mail: m, action: "OK")
            }))
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        }
    }

    func setUItoMail() {
        if let mail = mail {
            if mail.containsSecretKey {
                importSecretKeyDialog(first: true)
            }

            // mark mail as read if viewcontroller is open for more than 1.5 sec
            let delay = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delay) {
                if let viewControllers = self.navigationController?.viewControllers {
                    for viewController in viewControllers {
                        if viewController.isKind(of: ReadViewController.self) {
                            mail.isRead = true
                        }
                    }
                }
            }

            if let name = mail.from.contact?.nameOptional {
                senderTokenField.delegate?.tokenField!(senderTokenField, didEnterText: name, mail: mail.from.mailAddress)
            } else {
                senderTokenField.delegate?.tokenField!(senderTokenField, didEnterText: mail.from.mailAddress, mail: mail.from.mailAddress)
            }

            for receiver in mail.getReceivers() {
                if let displayname = receiver.contact?.nameOptional {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: displayname, mail: receiver.address)
                } else {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: receiver.address, mail: receiver.address)
                }
            }

            for receiver in mail.getCCs() {
                if let displayname = receiver.contact?.nameOptional {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: displayname, mail: receiver.address)
                } else {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: receiver.address, mail: receiver.address)
                }
            }

            for receiver in mail.getBCCs() {
                if let displayname = receiver.contact?.nameOptional {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: displayname, mail: receiver.address)
                } else {
                    toTokenField.delegate?.tokenField!(toTokenField, didEnterText: receiver.address, mail: receiver.address)
                }
            }

            if senderTokenField.frame.height > 60 {
                senderTokenField.collapse()
            }

            if toTokenField.frame.height > 60 {
                toTokenField.collapse()
            }

            receivedTime.text = mail.timeString

            if let subj = mail.subject {
                if subj.trimmingCharacters(in: CharacterSet.whitespaces).count > 0 {
                    subject.text = subj
                } else {
                    subject.text = NSLocalizedString("SubjectNo", comment: "This mail has no subject")
                }
            }

            if mail.isEncrypted && !mail.unableToDecrypt {
                messageBody.text = mail.decryptedBody
            } else {
                messageBody.text = mail.body
            }
            messageBody.text = messageBody.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).appending("\n")

            // NavigationBar Icon
            let iconView = UIImageView()
            iconView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            iconView.contentMode = .scaleAspectFit
            var icon: UIImage
            if mail.trouble {
                icon = IconsStyleKit.imageOfLetterCorrupted
            } else if mail.isSecure {
                icon = IconsStyleKit.imageOfLetterOpen
            } else {
                icon = IconsStyleKit.imageOfPostcard
            }
            iconView.image = icon
            iconButton.setImage(icon, for: UIControlState())

            // Mail info text
            if mail.trouble {
                infoSymbol.text = "!"
                infoSymbol.textColor = ThemeManager.troubleMessageColor()
                infoHeadline.text = NSLocalizedString("corruptedHeadline", comment: "This mail is corrupted")
                infoHeadline.textColor = UIColor.black
                infoText.text = NSLocalizedString("corruptedText", comment: "This mail is corrupted")
                infoCell.setNeedsLayout()
                infoCell.layoutIfNeeded()
                infoCell.translatesAutoresizingMaskIntoConstraints = true
            } else if mail.isEncrypted && mail.unableToDecrypt {
                infoSymbol.text = "?"
                infoSymbol.textColor = ThemeManager.unencryptedMessageColor()
                infoHeadline.text = NSLocalizedString("couldNotDecryptHeadline", comment: "Message could not be decrypted")
                infoHeadline.textColor = UIColor.gray
                infoText.text = NSLocalizedString("couldNotDecryptText", comment: "Message could not be decrypted")
            } else if isNewPubKey ?? false {
                infoSymbol.text = "!"
                infoSymbol.textColor = ThemeManager.unencryptedMessageColor()
                infoHeadline.text = NSLocalizedString("newKeyHeadline", comment: "Message contained a new public key")
                infoHeadline.textColor = UIColor.gray
                infoText.text = NSLocalizedString("newKeyText", comment: "Message contained a new public key")
            } else if mail.from.hasKey && !mail.isSecure {
                infoSymbol.text = "?"
                infoSymbol.textColor = ThemeManager.unencryptedMessageColor()
                infoHeadline.text = NSLocalizedString("encryptedBeforeHeadline", comment: "The sender has encrypted before")
                infoHeadline.textColor = UIColor.gray
                infoText.text = NSLocalizedString("encryptedBeforeText", comment: "The sender has encrypted before")
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "answerTo" && (sender is UIBarButtonItem || (sender as? String ?? "noReaction") == "reactButton") {
            let navigationController = segue.destination as? UINavigationController
            if let controller = navigationController?.topViewController as? SendViewController, let mail = mail {
                controller.sendViewDelegate = self
                if isDraft {
                    let prefillMail = EphemeralMail.init(to: mail.to, cc: mail.cc ?? NSSet.init(), bcc: mail.bcc ?? NSSet.init(), subject: mail.subject, body: mail.body, uid: mail.uid, predecessor: mail.predecessor)
                    controller.prefilledMail = prefillMail
                    return
                }
                let askForConfirmation = (sender as? String ?? "noReaction") == "reactButton"

                var answerTo = [mail.from]
                var answerCC = [Mail_Address]()
                var body = NSLocalizedString("mail from", comment: "describing who send the mail") + " "
                body.append(mail.from.mailAddress)
                let time = DateFormatter.init()
                time.dateStyle = .short
                time.timeStyle = .short
                time.locale = Locale.current
                body.append(" " + NSLocalizedString("sent at", comment: "describing when the mail was send") + " " + time.string(from: mail.date))
                body.append("\n" + NSLocalizedString("To", comment: "describing adressee") + ": ")
                let myAddress = UserManager.loadUserValue(Attribute.userAddr) as! String
                if mail.to.count > 0 {
                    for case let mail as Mail_Address in mail.to {
                        body.append("\(mail.address), ")
                        if mail.address != myAddress && !askForConfirmation {
                            answerTo.append(mail)
                        }
                    }
                }
                if mail.cc?.count ?? 0 > 0 {
                    body.append("\n\(NSLocalizedString("Cc", comment: "")): ")
                    for case let mail as Mail_Address in mail.cc! {
                        body.append("\(mail.address), ")
                        if mail.address != myAddress && !askForConfirmation {
                            answerCC.append(mail)
                        }
                    }
                }
                body.append("\n" + NSLocalizedString("subject", comment: "describing what subject was choosen") + ": " + (mail.subject ?? ""))
                body.append("\n------------------------\n\n" + (mail.decryptedBody ?? mail.body ?? ""))
                body = body.components(separatedBy: "\n").map { line in
                    if line.hasPrefix(">") {
                        return ">" + line
                    }
                    return "> " + line
                }.reduce("", { $0 + "\n" + $1 })

                if askForConfirmation {
                    body = NSLocalizedString("didYouSendThis", comment: "") + body
                } else {
                    body = UserManager.loadUserSignature() + body
                }

                var subject = NSLocalizedString("Re", comment: "prefix for subjects of answered mails") + ": " + NSLocalizedString("SubjectNo", comment: "there is no subject")
                if let subj = mail.subject {
                    if subj.hasPrefix("Re:") || subj.hasPrefix("RE:") || subj.hasPrefix("Aw:") || subj.hasPrefix("AW:") {
                        subject = subj
                    } else {
                        subject = NSLocalizedString("Re", comment: "prefix for subjects of answered mails") + ": " + subj
                    }
                }

                let answerMail = EphemeralMail(to: NSSet.init(array: answerTo), cc: NSSet.init(array: answerCC), bcc: [], date: mail.date, subject: subject, body: body, uid: mail.uid, predecessor: mail)

                controller.prefilledMail = answerMail
            }
        } else if segue.identifier == "answerTo" { // New Mail from data detector action
            let navigationController = segue.destination as? UINavigationController
            if let controller = navigationController?.topViewController as? SendViewController {

                let answerTo = sender as? String ?? "" // TODO: Convert String into MailAddress(?)

                let answerMail = EphemeralMail(to: NSSet.init(array: [answerTo]), cc: NSSet.init(array: []), bcc: [], date: Date(), subject: "", body: "", uid: 0, predecessor: nil) 

                controller.sendViewDelegate = self
                controller.prefilledMail = answerMail
            }
        } else if segue.identifier == "showContact" {
            let destinationVC = segue.destination as! ContactViewController
            if let sender = sender as? [String: AnyObject?] {
                destinationVC.keyRecord = (sender["record"] as! KeyRecord)
                destinationVC.highlightEmail = (sender["email"] as! String)
            }
        }
    }

    func newMailCallback(Address: String) {
        performSegue(withIdentifier: "answerTo", sender: Address)
    }

    func newSecretkeyPassword(textField: UITextField!) {
        if let tField = textField {
            tField.isSecureTextEntry = true
            secretKeyPasswordField = tField
        }
    }

    func importSecretKey(alertAction: UIAlertAction!) {
        Logger.log(importPrivateKeyPopupClose: mail, doImport: true)
        if (alertAction) != nil {
            if let pw = secretKeyPasswordField?.text {
                do {
                    _ = try mail?.processSecretKey(pw: pw)
                    Logger.log(importPrivateKey: mail, success: true)
                } catch _ {
                    Logger.log(importPrivateKey: mail, success: false)
                    importSecretKeyDialog(first: false)
                }
            }
        }
    }

    private func importSecretKeyDialog(first: Bool) {
        Logger.log(importPrivateKeyPopupOpen: mail)
        var message = NSLocalizedString("Please, enter the password to import the new secret.", comment: "NewSecretKeyMessage")
        if !first {
            message = NSLocalizedString("Wrong password! Please, enter the password to import the new secret again.", comment: "NewSecretKeyMessage")
        }
        let alert = UIAlertController(title: NSLocalizedString("New secret", comment: "NewSecretKeyTitle"), message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("No import", comment: "NoSecretKeyImport"), style: UIAlertActionStyle.destructive, handler: { (_: UIAlertAction) -> Void in
                Logger.log(importPrivateKeyPopupClose: self.mail, doImport: false)
            }))

        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Import secret Key"), style: UIAlertActionStyle.default, handler: importSecretKey))
        alert.addTextField(configurationHandler: newSecretkeyPassword(textField:))
        self.present(alert, animated: true, completion: nil)
    }
}

extension ReadViewController: SendViewDelegate {
    func compositionDiscarded() {

    }

    func compositionSavedAsDraft() {
        compositionSent()
    }

    func compositionSent() {
        reactButton.isEnabled = false
        if isDraft {
            if let mail = mail {
                AppDelegate.getAppDelegate().mailHandler.setFlag(mail.uid, flags: MCOMessageFlag.deleted, folder: mail.folder.path)
            }
            self.navigationController?.viewControllers.removeLast()
        }
    }
}

class ReadTextDelegate: NSObject, UITextViewDelegate {
    var callback: ((String) -> ())?

    @available(iOS, deprecated: 10.0)
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        if url.scheme == "mailto" {
            callback?(url.absoluteString.replacingOccurrences(of: "mailto:", with: ""))
            return false
        }
        return true
    }

    @available(iOS 10.0, *)
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if url.scheme == "mailto" {
            callback?(url.absoluteString.replacingOccurrences(of: "mailto:", with: ""))
            return false
        }
        return true
    }
}
