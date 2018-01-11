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
    
    var keyboardOpened = false
    var keyboardY: CGFloat = 0
    var keyboardHeight: CGFloat = 0
    var UISecurityState = true
    var toSecure = true
    var ccSecure = true
    var dataDelegate = VENDataDelegate()
    var mailHandler = AppDelegate.getAppDelegate().mailHandler
    var tableDataDelegate = TableViewDataDelegate(insertCallback: { (name: String, address: String) -> Void in return })
    var collectionDataDelegate = CollectionDataDelegate(suggestionFunc: AddressHandler.frequentAddresses, insertCallback: { (name: String, address: String) -> Void in return })
    var recognizer: UIGestureRecognizer = UIGestureRecognizer.init()

    var prefilledMail: EphemeralMail? = nil
    var toField: String? = nil
    var sendEncryptedIfPossible = true

	var invitationSelection = InvitationSelection()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataDelegate = VENDataDelegate(changeFunc: self.editName, tappedWhenSelectedFunc: self.showContact, beginFunc: self.beginEditing, endFunc: self.endEditing, deleteFunc: { () -> Void in return })
        tableDataDelegate = TableViewDataDelegate(insertCallback: self.insertName)
        collectionDataDelegate = CollectionDataDelegate(suggestionFunc: AddressHandler.frequentAddresses, insertCallback: self.insertName)
        startIconAnimation()

        textView.font = UIFont.systemFont(ofSize: 17)
        textView.text = ""

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

        if let to = toField {
            let ezCon = DataHandler.handler.getContactByAddress(to)
            toText.delegate?.tokenField!(toText, didEnterText: ezCon.name, mail: to)
        } else if let prefilledMail = prefilledMail {
            for case let mail as MailAddress in prefilledMail.to {
                if mail.mailAddress != UserManager.loadUserValue(Attribute.userAddr) as! String {
                    toText.delegate?.tokenField!(toText, didEnterText: mail.mailAddress)
                }
            }
            for case let mail as String in prefilledMail.to { //TODO: remove once adresses can be created
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

        ccText.inputTextFieldKeyboardType = UIKeyboardType.emailAddress
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

        sendEncryptedIfPossible = currentSecurityState
    }

    deinit {
        print("===============|| SendViewController deinitialized ||===============")
    }

    override func viewWillAppear(_ animated: Bool) {
        updateNavigationBar()
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
                }
                    else {
                        self.ccCollectionviewHeight.constant = 1
                        self.ccCollectionview.isHidden = true
                }
            }
            if self.toText.isFirstResponder {
                if self.collectionDataDelegate.collectionView(self.toCollectionview, numberOfItemsInSection: 0) > 0 {
                    self.toCollectionview.reloadData()
                    self.toCollectionviewHeight.constant = 100
                    self.toCollectionview.isHidden = false
                }
                    else {
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
                var to = [MailAddress]()
                var cc = [MailAddress]()
                for mail in toText.mailTokens {
                    if let mail = mail as? String { // , !EnzevalosEncryptionHandler.hasKey(mail)
                        to.append(DataHandler.handler.getMailAddress(mail, temporary: false))
                    }
                }
                for mail in ccText.mailTokens {
                    if let mail = mail as? String { // , !EnzevalosEncryptionHandler.hasKey(mail)
                        cc.append(DataHandler.handler.getMailAddress(mail, temporary: false))
                    }
                }

                let mail = EphemeralMail(to: NSSet.init(array: to), cc: NSSet.init(array: cc), bcc: NSSet.init(), date: Date(), subject: NSLocalizedString("inviteSubject", comment: "Subject for the invitation mail"), body: NSLocalizedString("inviteText", comment: "Body for the invitation mail"), uid: 0, predecessor: nil)


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
                    tableviewHeight.constant = keyboardY - tableviewBegin.constant - (self.navigationController?.navigationBar.frame.maxY)!
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
            }
                else {
                    self.toCollectionviewHeight.constant = 1
                    self.toCollectionview.isHidden = true
            }
        } else if tokenField == self.ccText {
            if self.collectionDataDelegate.collectionView(self.ccCollectionview, numberOfItemsInSection: 0) > 0 {
                self.ccCollectionview.reloadData()
                self.ccCollectionviewHeight.constant = 100
                self.ccCollectionview.isHidden = false
            }
                else {
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

    func newInput(_ tokenField: VENTokenField) {
        animateIfNeeded()
        reloadCollectionViews()
    }

    func keyboardOpen(_ notification: Notification) {
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
            
            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
                self.additionalSafeAreaInsets.bottom = intersection.height
                let desiredOffset = CGPoint(x: 0, y: -self.keyboardY)
                self.scrollview.setContentOffset(desiredOffset, animated: false)
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
        else {
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
                    self.scrollViewBottom.constant += (self.keyboardHeight-keyboardFrame.height)
                    let desiredOffset = CGPoint(x: 0, y: +(self.keyboardHeight-keyboardFrame.height))
                    self.keyboardHeight = keyboardFrame.height
                    self.scrollview.setContentOffset(desiredOffset, animated: false)
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
    func keyboardClose(_ notification: Notification) {
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
            
            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
                self.additionalSafeAreaInsets.bottom = intersection.height
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
        else {
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
            NSLog("Error sending email: \(String(describing: error))")
            //            AppDelegate.getAppDelegate().showMessage("An error occured", completion: nil) @jakob: wofür ist dieses showMessage aus AppDelegate gut?
            let alert = UIAlertController(title: NSLocalizedString("ReceiveError", comment: "There was an error"), message: NSLocalizedString("ErrorText", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Done", comment: ""), style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            NSLog("Send successful!")
            if (self.prefilledMail != nil) {
                if self.prefilledMail?.predecessor != nil {
                    self.prefilledMail?.predecessor?.isAnwered = true
                }
            }
            self.sendCompleted()
        }
    }

    func sendCompleted() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }


    //Navigationbar

    var currentSecurityState: Bool {
        toSecure = toText.dataSource!.isSecure!(toText) //TODO: Add pref enc field.
        ccSecure = ccText.dataSource!.isSecure!(ccText)
        return toSecure && ccSecure
    }

    var someoneWithKeyPresent: Bool {
        guard let toSource = toText.dataSource, let ccSource = ccText.dataSource else {
            return true
        }

        let toKey = toSource.someSecure(toText)
        let ccKey = ccSource.someSecure(ccText)

        return toKey || ccKey
    }

    func updateNavigationBar() {
        if currentSecurityState {
            self.navigationController?.navigationBar.barTintColor = ThemeManager.encryptedMessageColor()
        } else {
            self.navigationController?.navigationBar.barTintColor = ThemeManager.uncryptedMessageColor()
        }
    }

    func animateIfNeeded() {
        let currentState = currentSecurityState && sendEncryptedIfPossible
        if (currentState != self.UISecurityState) && ThemeManager.animation() {
            startIconAnimation()
            if currentState {
                UIView.animate(withDuration: 0.5, delay: 0, options: [UIViewAnimationOptions.curveEaseIn, UIViewAnimationOptions.allowUserInteraction], animations: {
                    self.navigationController?.navigationBar.barTintColor = ThemeManager.encryptedMessageColor()
                    self.navigationController?.navigationBar.layoutIfNeeded() //https://stackoverflow.com/questions/39515313/animate-navigation-bar-bartintcolor-change-in-ios10-not-working
                }, completion: nil)
            } else {
                UIView.animate(withDuration: 0.5, delay: 0, options: [UIViewAnimationOptions.curveEaseIn, UIViewAnimationOptions.allowUserInteraction], animations: {
                    self.navigationController?.navigationBar.barTintColor = ThemeManager.uncryptedMessageColor()
                    self.navigationController?.navigationBar.layoutIfNeeded()
                }, completion: nil)
            }
        }
        self.UISecurityState = currentState
    }

    func startIconAnimation() {
        if let view = iconButton.subviews.first as? AnimatedSendIcon {
            view.switchIcons()
        }
    }

    func iconButton(_ sender: AnyObject) {
        let alert: UIAlertController
        let url: String
        if !UISecurityState {
            alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "Postcard label"), message: NSLocalizedString("SendInsecureInfo", comment: "Postcard infotext"), preferredStyle: .alert)
            url = "https://enzevalos.org/infos/postcard"
            if subjectText.inputText() != NSLocalizedString("inviteSubject", comment: "") {
                alert.addAction(UIAlertAction(title: NSLocalizedString("inviteContacts", comment: "Allows users to invite contacts without encryption key"), style: .default, handler: {
                    (action: UIAlertAction) -> Void in
                    Logger.queue.async(flags: .barrier) {
                        Logger.log(close: url, mail: nil, action: "inviteSegue")
                    }
                    self.performSegue(withIdentifier: "inviteSegue", sender: nil)
                }))
            }
        } else {
            alert = UIAlertController(title: NSLocalizedString("Letter", comment: "Letter label"), message: NSLocalizedString("SendSecureInfo", comment: "Letter infotext"), preferredStyle: .alert)
            url = "https://enzevalos.org/infos/letter"
        }
        if someoneWithKeyPresent {
            if sendEncryptedIfPossible {
                alert.addAction(UIAlertAction(title: NSLocalizedString("sendInsecure", comment: "This mail should be send insecurely"), style: .default, handler: { (action: UIAlertAction!) -> Void in
                    Logger.queue.async(flags: .barrier) {
                        Logger.log(close: url, mail: nil, action: "sendInsecure")
                    }
                    self.sendEncryptedIfPossible = false
                    DispatchQueue.main.async { self.animateIfNeeded() }
                }))
            } else {
                alert.addAction(UIAlertAction(title: NSLocalizedString("sendSecureIfPossible", comment: "This mail should be send securely"), style: .default, handler: { (action: UIAlertAction!) -> Void in
                    Logger.queue.async(flags: .barrier) {
                        Logger.log(close: url, mail: nil, action: "sendSecureIfPossible")
                    }
                    self.sendEncryptedIfPossible = true
                    DispatchQueue.main.async { self.animateIfNeeded() }
                }))
            }
        }
        Logger.queue.async(flags: .barrier) {
            Logger.log(open: url, mail: nil)
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("MoreInformation", comment: "More Information label"), style: .default, handler: { (action: UIAlertAction!) -> Void in
            Logger.queue.async(flags: .barrier) {
                Logger.log(close: url, mail: nil, action: "openURL")
            }
            UIApplication.shared.openURL(URL(string: url)!)
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) -> Void in
            Logger.queue.async(flags: .barrier) {
                Logger.log(close: url, mail: nil, action: "OK")
            }
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
        if textView.text == "" && toText.mailTokens.count == 0 && ccText.mailTokens.count == 0 && subjectText.inputText() == "" {
            self.navigationController?.dismiss(animated: true, completion: nil)
        } else {
            let toEntrys = toText.mailTokens
            let ccEntrys = ccText.mailTokens
            let subject = subjectText.inputText()!
            let message = textView.text!

            alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: NSLocalizedString("discardButton", comment: "discard"), style: .destructive, handler: { (action: UIAlertAction!) -> Void in
                self.navigationController?.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("SaveToDrafts", comment: "save the written E-Mail as draft"), style: .default, handler: { (action: UIAlertAction!) -> Void in
                self.mailHandler.createDraft(toEntrys as NSArray as! [String], ccEntrys: ccEntrys as NSArray as! [String], bccEntrys: [], subject: subject, message: message, callback: { (error: Error?) -> Void in
                    if let error = error {
                        print(error)
                    } else {
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    }
                })
                self.navigationController?.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "cancel"), style: .cancel, handler: { (action: UIAlertAction!) -> Void in
                firstResponder?.becomeFirstResponder()
            }))
            DispatchQueue.main.async(execute: {
                self.view.endEditing(true)
                self.present(alert, animated: true, completion: nil)
            })
        }
    }

    @IBAction func pressSend(_ sender: AnyObject) {
        let toEntrys = toText.mailTokens
        let ccEntrys = ccText.mailTokens
        let subject = subjectText.inputText()!
        let message = textView.text!

        mailHandler.send(toEntrys as NSArray as! [String], ccEntrys: ccEntrys as NSArray as! [String], bccEntrys: [], subject: subject, message: message, sendEncryptedIfPossible: sendEncryptedIfPossible, callback: self.mailSend)
    }
}

extension SendViewController: UIGestureRecognizerDelegate {
    @IBAction func tapped(_ sender: UITapGestureRecognizer) {
        if let view = sender.view, view == scrollview, sender.location(in: view).y >= textView.frame.minY {
            textView.becomeFirstResponder()
        }
    }
}

extension VENTokenFieldDataSource {
    func someSecure(_ tokenField: VENTokenField) -> Bool {
        var secure = false
        for entry in tokenField.mailTokens {
            var hasKey = false
            if let madr = DataHandler.handler.findMailAddress(adr: entry as! String) {
                hasKey = madr.hasKey
            }
            secure = secure || hasKey
        }

        return secure
    }
}
