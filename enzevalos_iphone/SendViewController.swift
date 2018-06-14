//
//  ViewController.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 01.07.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import UIKit
import VENTokenField
import Contacts
import KeychainAccess

class SendViewController: UIViewController {

    @IBOutlet weak var button: UIBarButtonItem!
    @IBOutlet weak var iconButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var toText: VENTokenField!
    @IBOutlet weak var toHeight: NSLayoutConstraint!
    @IBOutlet weak var seperator1Height: NSLayoutConstraint!
    @IBOutlet weak var ccText: VENTokenField!
    @IBOutlet weak var ccHeight: NSLayoutConstraint!
    @IBOutlet weak var seperator2Height: NSLayoutConstraint!
    @IBOutlet weak var subjectText: VENTokenField!
    @IBOutlet weak var seperator3Height: NSLayoutConstraint!
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var tableviewBegin: NSLayoutConstraint!
    @IBOutlet weak var tableviewHeight: NSLayoutConstraint!
    @IBOutlet weak var toCollectionview: UICollectionView!
    @IBOutlet weak var toCollectionviewHeight: NSLayoutConstraint!
    @IBOutlet weak var ccCollectionview: UICollectionView!
    @IBOutlet weak var ccCollectionviewHeight: NSLayoutConstraint!
    @IBOutlet weak var seperator1Leading: NSLayoutConstraint!
    @IBOutlet weak var seperator2Leading: NSLayoutConstraint!
    @IBOutlet weak var seperator3Leading: NSLayoutConstraint!
    @IBOutlet weak var textViewLeading: NSLayoutConstraint!
    @IBOutlet weak var scrollViewBottom: NSLayoutConstraint!
    @IBOutlet weak var scrollviewRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var sendButton: UIBarButtonItem!

    var keyboardOpened = false
    var keyboardY: CGFloat = 0
    var keyboardHeight: CGFloat = 0
    var dataDelegate = VENDataDelegate()
    var mailHandler = AppDelegate.getAppDelegate().mailHandler
    var tableDataDelegate = TableViewDataDelegate(insertCallback: { (name: String, address: String) -> Void in return })
    var collectionDataDelegate = CollectionDataDelegate(suggestionFunc: AddressHandler.frequentAddresses, insertCallback: { (name: String, address: String) -> Void in return })
    var recognizer: UIGestureRecognizer = UIGestureRecognizer.init()
    var freeTextInviationTitle = StudySettings.freeTextInvitationTitle
    
    //These attributes may be interesting to set in a segue to SendViewController
    var prefilledMail: EphemeralMail? = nil
    weak var sendViewDelegate: SendViewDelegate?
    var invite: Bool = false
    var enforcePostcard: Bool = false
    
    
    var recipientSecurityState: SendViewContactSecurityState {
        if dataDelegate.numberOfTokens(in: toText) + dataDelegate.numberOfTokens(in: ccText) == 0{
            return .none
        }
        if dataDelegate.allSecure(toText) && dataDelegate.allSecure(ccText) {
            return .allSecure
        }
        if dataDelegate.allInsecure(toText) && dataDelegate.allInsecure(ccText) {
            return .allInsecure
        }
        return .mixed
    }
    
    var mailSecurityState: SendViewMailSecurityState {
        if enforcePostcard || (recipientSecurityState == .allInsecure || recipientSecurityState == .mixed) {
            if invitationSelection.selectedWords.count == 0 {
                return .postcard
            }
            if StudySettings.invitationsmode == .Censorship {
                return .extendedPostcard(.censored)
            }
            return .extendedPostcard(.partiallyEncrypted)
        }
        return .letter
    }
    
    var sendInProgress: Bool = false {
        didSet {
            if sendInProgress {
                self.view.endEditing(true)
            }
            sendButton.isEnabled = !sendInProgress
            textView.isEditable = !sendInProgress
            subjectText.isEnabled = !sendInProgress
            toText.isEnabled = !sendInProgress
            ccText.isEnabled = !sendInProgress
        }
    }

    var invitationSelection = InvitationSelection()

    override func viewDidLoad() {
        super.viewDidLoad()

        dataDelegate = VENDataDelegate(changeFunc: {[weak self] (tokenField: VENTokenField) in self?.editName(tokenField)},
                                       tappedWhenSelectedFunc: {[weak self] (email: String) in self?.showContact(email)},
                                       beginFunc: {[weak self] (tokenField: VENTokenField) in self?.beginEditing(tokenField)},
                                       endFunc: {[weak self] (tokenField: VENTokenField) in self?.endEditing(tokenField)},
                                       deleteFunc: { () -> Void in return })
        tableDataDelegate = TableViewDataDelegate(insertCallback: {[weak self] (name: String, address: String) in self?.insertName(name, address: address)})
        collectionDataDelegate = CollectionDataDelegate(suggestionFunc: AddressHandler.frequentAddresses, insertCallback: {[weak self] (name: String, address: String) in self?.insertName(name, address: address)})
        startIconAnimation()

        textView.font = UIFont.systemFont(ofSize: 17)
        textView.delegate = self

        subjectText.toLabelText = NSLocalizedString("Subject", comment: "subject label") + ": "

        let iconView = AnimatedSendIcon()
        iconView.frame = iconView.frame.offsetBy(dx: 0, dy: -10)
        iconButton.addSubview(iconView)

        toText.delegate = dataDelegate
        toText.dataSource = dataDelegate
        toText.inputTextFieldKeyboardType = UIKeyboardType.emailAddress
        toText.toLabelText = NSLocalizedString("To", comment: "to label") + ": "
        toText.setColorScheme(self.view.tintColor)
        toCollectionview.delegate = collectionDataDelegate
        toCollectionview.dataSource = collectionDataDelegate
        toCollectionview.register(UINib(nibName: "FrequentCell", bundle: nil), forCellWithReuseIdentifier: "frequent")
        toCollectionviewHeight.constant = 0
        ccText.delegate = dataDelegate
        ccText.dataSource = dataDelegate
        ccText.inputTextFieldKeyboardType = UIKeyboardType.emailAddress
        ccText.toLabelText = NSLocalizedString("Cc", comment: "copy label") + ": "
        ccText.setColorScheme(self.view.tintColor)
        ccCollectionview.delegate = collectionDataDelegate
        ccCollectionview.dataSource = collectionDataDelegate
        ccCollectionview.register(UINib(nibName: "FrequentCell", bundle: nil), forCellWithReuseIdentifier: "frequent")
        ccCollectionviewHeight.constant = 0
        toCollectionviewHeight.constant = 0

        subjectText.setColorScheme(self.view.tintColor)

        //will always be thrown, when a token was editied
        toText.addTarget(self, action: #selector(self.newInput(_:)), for: UIControlEvents.editingDidEnd)
        ccText.addTarget(self, action: #selector(self.newInput(_:)), for: UIControlEvents.editingDidEnd)

        if prefilledMail == nil {
            textView.text.append(UserManager.loadUserSignature())
        }

        if let prefilledMail = prefilledMail {
            for case let mail as MailAddress in prefilledMail.to {
                if mail.mailAddress != UserManager.loadUserValue(Attribute.userAddr) as! String {
                    toText.delegate?.tokenField!(toText, didEnterText: mail.mailAddress)
                }
            }
            for case let mail as String in prefilledMail.to {
                toText.delegate?.tokenField!(toText, didEnterText: mail)
            }
            for case let mail as MailAddress in prefilledMail.cc ?? [] {
                if mail.mailAddress != UserManager.loadUserValue(Attribute.userAddr) as! String {
                    ccText.delegate?.tokenField!(ccText, didEnterText: mail.mailAddress)
                }
            }

            subjectText.setText(prefilledMail.subject ?? "")
            textView.text.append(prefilledMail.body ?? "")
        }

        let sepConst: CGFloat = 1 / UIScreen.main.scale
        seperator1Height.constant = sepConst//0.5
        seperator2Height.constant = sepConst//0.5
        seperator3Height.constant = sepConst//0.5

        seperator1Leading.constant += toText.horizontalInset
        seperator2Leading.constant += ccText.horizontalInset
        seperator3Leading.constant += subjectText.horizontalInset

        textViewLeading.constant = seperator3Leading.constant - 4

        scrollview.clipsToBounds = true

        tableview.delegate = tableDataDelegate
        tableview.dataSource = tableDataDelegate
        tableview.register(UINib(nibName: "ContactCell", bundle: nil), forCellReuseIdentifier: "contacts")
        tableviewHeight.constant = 0

        let indexPath = IndexPath()
        tableview.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)

        //register KeyBoardevents
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardOpen(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardClose(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil);

        toText.tag = UIViewResolver.toText.rawValue
        ccText.tag = UIViewResolver.ccText.rawValue
        textView.tag = UIViewResolver.textView.rawValue
        tableview.tag = UIViewResolver.tableview.rawValue
        toCollectionview.tag = UIViewResolver.toCollectionview.rawValue
        ccCollectionview.tag = UIViewResolver.ccCollectionview.rawValue
        subjectText.tag = UIViewResolver.subjectText.rawValue
        scrollview.tag = UIViewResolver.scrollview.rawValue

        updateNavigationBar()

//        Logger.queue.async(flags: .barrier) {
        Logger.log(sendViewOpen: prefilledMail)
//        }
    }

    deinit {
        print("===============|| SendViewController deinitialized ||===============")
    }

    func updateSecurityUI() {
        animateIfNeeded()
        self.updateMarkedText(for: self.textView)
        self.showFirstDialogIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
//        Logger.queue.async(flags: .barrier) {
        Logger.log(sendViewClose: prefilledMail)
//        }
        super.viewWillDisappear(animated)
    }

    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)

        if parent == nil {
            UIView.animate(withDuration: 0.3, animations: { self.navigationController?.navigationBar.barTintColor = ThemeManager.defaultColor })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func reloadCollectionViews() {
        collectionDataDelegate.alreadyInserted = (toText.mailTokens as NSArray as! [String]) + (ccText.mailTokens as NSArray as! [String])
        DispatchQueue.main.async {
            self.collectionDataDelegate.alreadyInserted = (self.toText.mailTokens as NSArray as! [String]) + (self.ccText.mailTokens as NSArray as! [String])
            if self.ccText.isFirstResponder {
                if self.collectionDataDelegate.collectionView(self.ccCollectionview, numberOfItemsInSection: 0) > 0 {
                    self.ccCollectionview.reloadData()
                    self.ccCollectionviewHeight.constant = 100
                    self.ccCollectionview.isHidden = false
                } else {
                    self.ccCollectionviewHeight.constant = 1
                    self.ccCollectionview.isHidden = true
                }
            }
            if self.toText.isFirstResponder {
                if self.collectionDataDelegate.collectionView(self.toCollectionview, numberOfItemsInSection: 0) > 0 {
                    self.toCollectionview.reloadData()
                    self.toCollectionviewHeight.constant = 100
                    self.toCollectionview.isHidden = false
                } else {
                    self.toCollectionviewHeight.constant = 1
                    self.toCollectionview.isHidden = true
                }
            }

            self.toCollectionview.reloadData()
            self.ccCollectionview.reloadData()
        }
    }

    func showContact(_ email: String) {
        let records = DataHandler.handler.getContactByAddress(email).records
        for r in records {
            for address in r.addresses {
                if address.mailAddress == email && address.hasKey == r.hasKey {
                    performSegue(withIdentifier: "showContact", sender: ["record": r, "email": email])
                    self.view.endEditing(true)
                    return
                }
            }
        }

        //        performSegueWithIdentifier("showContact", sender: records.first)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showContact" {
            let destinationVC = segue.destination as! ContactViewController
            if let sender = sender as? [String: AnyObject?] {
                destinationVC.keyRecord = (sender["record"] as! KeyRecord)
                destinationVC.highlightEmail = (sender["email"] as! String)
            }
        } else if segue.identifier == "inviteSegue" {
            let navigationController = segue.destination as? UINavigationController
            if let controller = navigationController?.topViewController as? SendViewController {
                controller.invite = true
                var to = [MailAddress]()
                var cc = [MailAddress]()
                for mail in toText.mailTokens {
                    if let mail = mail as? String {
                        to.append(DataHandler.handler.getMailAddress(mail, temporary: false))
                    }
                }
                for mail in ccText.mailTokens {
                    if let mail = mail as? String {
                        cc.append(DataHandler.handler.getMailAddress(mail, temporary: false))
                    }
                }

                let body = String(format: NSLocalizedString("inviteText", comment: "Body for the invitation mail"),StudySettings.studyID)
                let mail = EphemeralMail(to: NSSet.init(array: to), cc: NSSet.init(array: cc), subject: NSLocalizedString("inviteSubject", comment: "Subject for the invitation mail"), body: body)


                controller.prefilledMail = mail
            }
        } else if segue.identifier == "inviteSegueStudy" {
            let navigationController = segue.destination as? UINavigationController
            if let controller = navigationController?.topViewController as? SendViewController {
                controller.invite = true

                var to = [MailAddress]()
                var cc = [MailAddress]()
                for mail in toText.mailTokens {
                    if let mail = mail as? String {
                        to.append(DataHandler.handler.getMailAddress(mail, temporary: false))
                    }
                }
                for mail in ccText.mailTokens {
                    if let mail = mail as? String {
                        cc.append(DataHandler.handler.getMailAddress(mail, temporary: false))
                    }
                }

                let mail = EphemeralMail(to: NSSet.init(array: to), cc: NSSet.init(array: cc), bcc: NSSet.init(), date: Date(), subject: NSLocalizedString("inviteSubject", comment: "Subject for the invitation mail"), body: "\n\nMehr Informationen unter https://userpage.fu-berlin.de/letterbox/", uid: 0, predecessor: nil)
                controller.prefilledMail = mail
            }
        }
    }

    func editName(_ tokenField: VENTokenField) {
        if let inText = tokenField.inputText() {
            if inText != "" {
                searchContacts(inText)
                if tableDataDelegate.contacts != [] {
                    scrollview.isScrollEnabled = false
                    scrollview.contentOffset = CGPoint(x: 0, y: tokenField.frame.origin.y - self.topLayoutGuide.length)
                    tableviewBegin.constant = tokenField.frame.maxY - tokenField.frame.origin.y
                    if #available(iOS 11.0, *) {
                        if keyboardY > 0 {
                            tableviewHeight.constant = keyboardY - tableviewBegin.constant
                        } else {
                            tableviewHeight.constant = view.safeAreaLayoutGuide.layoutFrame.size.height - tableviewBegin.constant
                        }
                    } else {
                        if keyboardY > 0 {
                            tableviewHeight.constant = keyboardY - tableviewBegin.constant - (self.navigationController?.navigationBar.frame.maxY)!
                        } else {
                            tableviewHeight.constant = view.bounds.size.height - tableviewBegin.constant - (self.navigationController?.navigationBar.frame.maxY)!
                        }
                    }
                } else if !scrollview.isScrollEnabled {
                    scrollview.isScrollEnabled = true
                    tableviewHeight.constant = 0
                }
            } else if !scrollview.isScrollEnabled {
                scrollview.isScrollEnabled = true
                tableviewHeight.constant = 0
            }
        }
    }

    func beginEditing(_ tokenField: VENTokenField) {
        UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(rawValue: 7), animations: {
            if tokenField == self.toText {
                if self.collectionDataDelegate.collectionView(self.toCollectionview, numberOfItemsInSection: 0) > 0 {
                    self.toCollectionview.reloadData()
                    self.toCollectionviewHeight.constant = 100
                    self.toCollectionview.isHidden = false
                } else {
                    self.toCollectionviewHeight.constant = 1
                    self.toCollectionview.isHidden = true
                }
            } else if tokenField == self.ccText {
                if self.collectionDataDelegate.collectionView(self.ccCollectionview, numberOfItemsInSection: 0) > 0 {
                    self.ccCollectionview.reloadData()
                    self.ccCollectionviewHeight.constant = 100
                    self.ccCollectionview.isHidden = false
                } else {
                    self.ccCollectionviewHeight.constant = 1
                    self.ccCollectionview.isHidden = true
                }
            }
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    func endEditing(_ tokenField: VENTokenField) {
        UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(rawValue: 7), animations: {
            if tokenField == self.toText {
                self.toCollectionviewHeight.constant = 1
                self.toCollectionview.isHidden = true
            } else if tokenField == self.ccText {
                self.ccCollectionviewHeight.constant = 1
                self.ccCollectionview.isHidden = true
            }
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    func insertName(_ name: String, address: String) {
        let address = address.lowercased()
        if toText.isFirstResponder {
            toText.delegate?.tokenField!(toText, didEnterText: name, mail: address)
        } else if ccText.isFirstResponder {
            ccText.delegate?.tokenField!(ccText, didEnterText: name, mail: address)
        }
    }

    func searchContacts(_ prefix: String) {
        AppDelegate.getAppDelegate().requestForAccess({ access in
        })
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        if authorizationStatus == CNAuthorizationStatus.authorized {
            do {
                let contacts = try AppDelegate.getAppDelegate().contactStore.unifiedContacts(matching: CNContact.predicateForContacts(matchingName: prefix), keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: CNContactFormatterStyle.fullName), CNContactEmailAddressesKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor])
                tableDataDelegate.contacts = []
                tableDataDelegate.addresses = []
                tableDataDelegate.pictures = []
                for c in contacts {
                    for mail in c.emailAddresses {
                        if let name = CNContactFormatter.string(from: c, style: .fullName) {
                            self.tableDataDelegate.contacts.append(name)
                        } else {
                            self.tableDataDelegate.contacts.append(c.givenName + c.familyName)
                        }
                        self.tableDataDelegate.addresses.append(mail.value as String)
                        self.tableDataDelegate.pictures.append(c.getImageOrDefault())
                    }
                }
                tableview.reloadData()
            }
            catch {
                print("exception in contacts search")
            }
        } else {
            print("no Access!")
        }
    }

    @objc func newInput(_ tokenField: VENTokenField) {
        updateSecurityUI()
        reloadCollectionViews()
    }

    @objc func keyboardOpen(_ notification: Notification) {
        let animationDuration: TimeInterval = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
        let animationCurve = UIViewAnimationOptions(rawValue: animationCurveRaw)

        if #available(iOS 11.0, *) {

            guard let userInfo = notification.userInfo,
                let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                    return
            }

            let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
            let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: 0, dy: -additionalSafeAreaInsets.bottom)
            let intersection = safeAreaFrame.intersection(keyboardFrameInView)

            let animationDuration: TimeInterval = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve = UIViewAnimationOptions(rawValue: animationCurveRaw)

            self.keyboardY = keyboardFrameInView.minY

            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
                self.additionalSafeAreaInsets.bottom = intersection.height
                let desiredOffset = CGPoint(x: 0, y: 0)
                self.scrollview.setContentOffset(desiredOffset, animated: false)
                self.view.layoutIfNeeded()
            }, completion: nil)
        } else {
            var info = notification.userInfo!
            let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            keyboardY = keyboardFrame.origin.y
            if keyboardHeight == 0 {
                keyboardHeight = keyboardFrame.height

                UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
                    self.scrollViewBottom.constant -= self.keyboardHeight
                    let desiredOffset = CGPoint(x: 0, y: -self.keyboardHeight)
                    self.scrollview.setContentOffset(desiredOffset, animated: false)
                    self.view.layoutIfNeeded()
                }, completion: nil)
            } else {
                UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
                    self.scrollViewBottom.constant += (self.keyboardHeight - keyboardFrame.height)
                    let desiredOffset = CGPoint(x: 0, y: +(self.keyboardHeight - keyboardFrame.height))
                    self.keyboardHeight = keyboardFrame.height
                    self.scrollview.setContentOffset(desiredOffset, animated: false)
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }

    @objc func keyboardClose(_ notification: Notification) {
        let animationDuration: TimeInterval = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
        let animationCurve = UIViewAnimationOptions(rawValue: animationCurveRaw)

        if #available(iOS 11.0, *) {

            guard let userInfo = notification.userInfo,
                let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                    return
            }

            let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
            let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: 0, dy: -additionalSafeAreaInsets.bottom)
            let intersection = safeAreaFrame.intersection(keyboardFrameInView)

            self.keyboardY = 0

            let animationDuration: TimeInterval = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve = UIViewAnimationOptions(rawValue: animationCurveRaw)

            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
                self.additionalSafeAreaInsets.bottom = intersection.height
                self.view.layoutIfNeeded()
            }, completion: nil)
        } else {
            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
                self.scrollViewBottom.constant += self.keyboardHeight
                self.keyboardY = 0
                self.keyboardHeight = 0
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    func mailSend(_ error: Error?) {
        if (error != nil) {
            if AppDelegate.getAppDelegate().mailHandler.shouldTryRefreshOAUTH {
                AppDelegate.getAppDelegate().mailHandler.retryWithRefreshedOAuth { [weak self] in
                    self?.pressSend(nil)
                }
                return
            }
            NSLog("Error sending email: \(String(describing: error))")
            let alert = UIAlertController(title: NSLocalizedString("ReceiveError", comment: "There was an error"), message: NSLocalizedString("ErrorText", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Done", comment: ""), style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            sendInProgress = false
        } else {
            NSLog("Send successful!")
            if (self.prefilledMail != nil) {
                if self.prefilledMail?.predecessor != nil {
                    self.prefilledMail?.predecessor?.isAnwered = true
                }
            }
            let inviteMail = invite || mailSecurityState == .extendedPostcard(.censored) || mailSecurityState == .extendedPostcard(.partiallyEncrypted)
            
            if inviteMail {
                for addr in toText.mailTokens {
                    if let mailAddr = DataHandler.handler.findMailAddress(adr: addr as! String) {
                        if enforcePostcard || !mailAddr.hasKey {
                            mailAddr.invitations = mailAddr.invitations + 1
                        }
                    }
                }
                for addr in ccText.mailTokens {
                    if let mailAddr = DataHandler.handler.findMailAddress(adr: addr as! String) {
                        if enforcePostcard || !mailAddr.hasKey {
                            mailAddr.invitations = mailAddr.invitations + 1
                        }
                    }
                }
                DataHandler.handler.save(during: "invite")
            }
            if let delegate = sendViewDelegate {
                delegate.compositionSent()
            }
            sendInProgress = false
            self.sendCompleted()
        }
    }

    func sendCompleted() {
        if let code = self.invitationSelection.code, mailSecurityState == SendViewMailSecurityState.extendedPostcard(.partiallyEncrypted) {
            let controller = DialogViewController.present(on: self, with: .invitationCode(code: code))
            controller?.ctaAction = {
                let activityController = UIActivityViewController(activityItems: [code], applicationActivities: nil)
                controller?.present(activityController, animated: true, completion: nil)
                controller?.markDismissButton(with: .invitationCode(code: code))
            }

            controller?.dismissAction = { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
        else {
            self.navigationController?.dismiss(animated: true, completion: nil)
            return
        }
    }


    //Navigationbar
    
    func updateNavigationBar() {
        if mailSecurityState == .letter {
            self.navigationController?.navigationBar.barTintColor = ThemeManager.encryptedMessageColor()
        } else {
            self.navigationController?.navigationBar.barTintColor = ThemeManager.unencryptedMessageColor()
        }
    }

    func animateIfNeeded() {
        var uiSecurityState: SendViewMailSecurityState = .letter
        
        if let view = iconButton.subviews.first as? AnimatedSendIcon, view.isPostcardOnTop {
            uiSecurityState = .postcard
        }
        
        if ThemeManager.animation() {
            if mailSecurityState == .letter && uiSecurityState == .postcard {
                startIconAnimation()
                UIView.animate(withDuration: 0.5, delay: 0, options: [UIViewAnimationOptions.curveEaseIn, UIViewAnimationOptions.allowUserInteraction], animations: {
                    self.navigationController?.navigationBar.barTintColor = ThemeManager.encryptedMessageColor()
                    self.navigationController?.navigationBar.layoutIfNeeded() //https://stackoverflow.com/questions/39515313/animate-navigation-bar-bartintcolor-change-in-ios10-not-working
                }, completion: nil)
            } else if mailSecurityState != .letter && uiSecurityState == .letter {
                startIconAnimation()
                UIView.animate(withDuration: 0.5, delay: 0, options: [UIViewAnimationOptions.curveEaseIn, UIViewAnimationOptions.allowUserInteraction], animations: {
                    self.navigationController?.navigationBar.barTintColor = ThemeManager.unencryptedMessageColor()
                    self.navigationController?.navigationBar.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }

    func startIconAnimation() {
        if let view = iconButton.subviews.first as? AnimatedSendIcon {
            view.switchIcons()
        }
    }

    func iconButton(_ sender: AnyObject) {
        let alert: UIAlertController
        let url: String
        if mailSecurityState != .letter {
            alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "Postcard label"), message: enforcePostcard ? NSLocalizedString("SendInsecureInfoAll", comment: "Postcard infotext") : NSLocalizedString("SendInsecureInfo", comment: "Postcard infotext"), preferredStyle: .alert)
            url = "https://userpage.fu-berlin.de/letterbox/faq.html#headingPostcard"
            if subjectText.inputText() != NSLocalizedString("inviteSubject", comment: "") && !UserDefaults.standard.bool(forKey: "hideFreeTextInvitation") {
                alert.addAction(UIAlertAction(title: freeTextInviationTitle, style: .default, handler: {
                    (action: UIAlertAction) -> Void in
                    switch StudySettings.invitationsmode {
                    case .InviteMail:
                        self.performSegue(withIdentifier: "inviteSegue", sender: nil)
                    case .FreeText:
                        self.performSegue(withIdentifier: "inviteSegueStudy", sender: nil)
                    case .Censorship, .PasswordEnc:
                        DispatchQueue.main.async {
                            self.showHelpDialog()
                        }
                    }

                    Logger.log(close: url, mail: nil, action: "invitationButton in mode \(StudySettings.invitationsmode)")
                }))
            }
        } else {
            alert = UIAlertController(title: NSLocalizedString("Letter", comment: "Letter label"), message: NSLocalizedString("SendSecureInfo", comment: "Letter infotext"), preferredStyle: .alert)
            url = "https://userpage.fu-berlin.de/letterbox/faq.html#secureMail"
        }
        if recipientSecurityState != .allInsecure {
            if enforcePostcard {
                alert.addAction(UIAlertAction(title: recipientSecurityState == .allInsecure || recipientSecurityState == .mixed ? NSLocalizedString("sendSecureIfPossible", comment: "This mail should be send securely to people with keys") : NSLocalizedString("sendSecure", comment: "This mail should be send securely"), style: .default, handler: { (action: UIAlertAction!) -> Void in
                    Logger.log(close: url, mail: nil, action: "sendSecureIfPossible")
                    self.enforcePostcard = false
                    DispatchQueue.main.async { self.updateSecurityUI() }
                }))
            } else {
                alert.addAction(UIAlertAction(title: recipientSecurityState == .allInsecure || recipientSecurityState == .mixed ? NSLocalizedString("sendInsecureAll", comment: "This mail should be send insecurely to everyone, including contacts with keys") : NSLocalizedString("sendInsecure", comment: "This mail should be send insecurely"), style: .default, handler: { (action: UIAlertAction!) -> Void in
                    Logger.log(close: url, mail: nil, action: "sendInsecure")
                    self.enforcePostcard = true
                    DispatchQueue.main.async { self.updateSecurityUI() }
                }))
            }
        }
        Logger.log(open: url, mail: nil)
        alert.addAction(UIAlertAction(title: NSLocalizedString("MoreInformation", comment: "More Information label"), style: .default, handler: { (action: UIAlertAction!) -> Void in
            Logger.log(close: url, mail: nil, action: "openURL")
            UIApplication.shared.openURL(URL(string: url)!)
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) -> Void in
            Logger.log(close: url, mail: nil, action: "OK")
        }))
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
        })
    }

    @IBAction func iconButtonPressed(_ sender: AnyObject) {
        iconButton(sender)
    }

    @IBAction func pressCancel(_ sender: AnyObject) {
        var alert: UIAlertController

        var firstResponder: UIView?
        for view in [toText, ccText, subjectText, textView] as [UIView] {
            if view.isFirstResponder {
                firstResponder = view
            }
        }
        if (textView.text.trimmed() == "" || textView.text.trimmed() == UserManager.loadUserSignature().trimmed()) && toText.mailTokens.count == 0 && ccText.mailTokens.count == 0 && subjectText.inputText()?.trimmed() == "" {
            self.navigationController?.dismiss(animated: true, completion: nil)
        } else {
            let toEntrys = toText.mailTokens
            let ccEntrys = ccText.mailTokens
            let subject = subjectText.inputText()!
            let message = textView.text!

            alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: NSLocalizedString("discardButton", comment: "discard"), style: .destructive, handler: { [weak self] (action: UIAlertAction!) -> Void in
                if let delegate = self?.sendViewDelegate {
                    delegate.compositionDiscarded()
                }
                self?.navigationController?.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("SaveAsDraft", comment: "save the written E-Mail as draft"), style: .default, handler: { [weak self] (action: UIAlertAction!) -> Void in
                self?.mailHandler.createDraft(toEntrys as NSArray as! [String], ccEntrys: ccEntrys as NSArray as! [String], bccEntrys: [], subject: subject, message: message, callback: { [weak self] (error: Error?) -> Void in
                    if let error = error {
                        print(error)
                    } else {
                        if let delegate = self?.sendViewDelegate {
                            delegate.compositionSavedAsDraft()
                        }
                        self?.navigationController?.dismiss(animated: true, completion: nil)
                    }
                })
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "cancel"), style: .cancel, handler: { (action: UIAlertAction!) -> Void in
                firstResponder?.becomeFirstResponder()
            }))
            DispatchQueue.main.async(execute: { [weak self] in
                self?.view.endEditing(true)
                self?.present(alert, animated: true, completion: nil)
            })
        }
    }

    @IBAction func pressSend(_ sender: AnyObject?) {
        sendInProgress = true

        let toEntrys = toText.mailTokens
        let ccEntrys = ccText.mailTokens
        let subject = subjectText.inputText()!
        let (hmtlmessage, counterTextparts, plaintext) = self.htmlMessage()
        let message: String = (plaintext ?? self.textView.text)
        let inviteMail = invite || mailSecurityState == .extendedPostcard(.censored) || mailSecurityState == .extendedPostcard(.partiallyEncrypted)
        
        mailHandler.send(toEntrys as NSArray as! [String], ccEntrys: ccEntrys as NSArray as! [String], bccEntrys: [], subject: subject, message: message, sendEncryptedIfPossible: !enforcePostcard, callback: self.mailSend, htmlContent: hmtlmessage, inviteMail: inviteMail, textparts: counterTextparts)
    }
}

extension SendViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == scrollviewRecognizer && touch.location(in: textView).y >= 0 {
            return true
        }
        return false
    }

    @IBAction func tapped(_ sender: UITapGestureRecognizer) {
        if let view = sender.view, view == scrollview, sender.location(in: view).y >= textView.frame.minY {
            textView.becomeFirstResponder()
        }
    }
}

extension VENTokenFieldDataSource {

    /// Returns a bool showing whether all contacts in the field have a key. Returns true if no contacts are present.
    func allSecure(_ tokenField: VENTokenField) -> Bool {
        for entry in tokenField.mailTokens {
            if !DataHandler.handler.hasKey(adr: entry as! String) {
                return false
            }
        }

        return true
    }
    
    /**
     Returns a bool showing whether all contacts in the field have a key. Returns true if no contacts are present.
     */
    func allInsecure(_ tokenField: VENTokenField) -> Bool {
        for entry in tokenField.mailTokens {
            if DataHandler.handler.hasKey(adr: entry as! String) {
                return false
            }
        }
        
        return true
    }
}

extension String {
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
