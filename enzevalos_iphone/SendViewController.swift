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

class SendViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate, VENTokenFieldDelegate {

    var imageView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 5, width: 200, height: 45))
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

    var keyboardOpened = false
    var keyboardY: CGFloat = 0
    var reducedSize: CGFloat = 0
    var secureState = true
    var toSecure = true
    var ccSecure = true
    var dataDelegate = VENDataDelegate()
    var mailHandler = AppDelegate.getAppDelegate().mailHandler
    var tableDataDelegate = TableViewDataDelegate(insertCallback: { (name: String, address: String) -> Void in return })
    var collectionDataDelegate = CollectionDataDelegate(suggestionFunc: AddressHandler.frequentAddresses, insertCallback: { (name: String, address: String) -> Void in return })
    var recognizer: UIGestureRecognizer = UIGestureRecognizer.init()

    var answerTo: Mail? = nil
    var toField: String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        dataDelegate = VENDataDelegate(changeFunc: self.editName, tappedWhenSelectedFunc: self.showContact, deleteFunc: /*{() -> Void in return}*/self.addFrequentCellIfPossible)
        tableDataDelegate = TableViewDataDelegate(insertCallback: self.insertName)
        collectionDataDelegate = CollectionDataDelegate(suggestionFunc: AddressHandler.frequentAddresses, insertCallback: self.insertName)
        setAnimation()

        textView.delegate = self
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.text = ""

        subjectText.toLabelText = NSLocalizedString("Subject", comment: "subject label") + ": "

        iconButton.addSubview(AnimatedSendIcon())
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
        //ccCollectionview.translatesAutoresizingMaskIntoConstraints = true
        //toCollectionview.translatesAutoresizingMaskIntoConstraints = true
        toCollectionviewHeight.constant = 0
        
        /*for constraint in toCollectionview.constraints {
            if constraint.firstAttribute == NSLayoutAttribute.Height {
                constraint.constant = 0
            }
        }*/
        
        subjectText.delegate = self
        subjectText.setColorScheme(self.view.tintColor)

        //will always be thrown, when a token was editied
        toText.addTarget(self, action: #selector(self.newInput(_:)), for: UIControlEvents.editingDidEnd)
        ccText.addTarget(self, action: #selector(self.newInput(_:)), for: UIControlEvents.editingDidEnd)

        if let to = toField {
            let ezCon = DataHandler.handler.getContactByAddress(to)
            toText.delegate?.tokenField!(toText, didEnterText: ezCon.name, mail: to)
        } else if answerTo != nil {
            toText.delegate?.tokenField!(toText, didEnterText: (answerTo?.from.address)!)
            for r in (answerTo?.getReceivers())! {
                if r.address != UserManager.loadUserValue(Attribute.userAddr) as! String {
                    ccText.delegate?.tokenField!(ccText, didEnterText: r.address)
                }
            }
            subjectText.setText(NSLocalizedString("Re", comment: "prefix for subjects of answered mails") + ": " + (answerTo?.subject!)!)
            textView.text = NSLocalizedString("mail from", comment: "describing who send the mail") + " "
            textView.text.append((answerTo?.from.address)!)
            textView.text.append(" " + NSLocalizedString("sent at", comment: "describing when the mail was send") + " " + (answerTo?.timeString)!)
            textView.text.append("\n" + NSLocalizedString("to", comment: "describing adressee") + ": ")
            textView.text.append(UserManager.loadUserValue(Attribute.userAddr) as! String)
            if ccText.mailTokens.count > 0 {
                textView.text.append(", ")
            }
            textView.text.append(ccText.mailTokens.componentsJoined(by: ", "))
            textView.text.append("\n" + NSLocalizedString("subject", comment: "describing what subject was choosen") + ": " + (answerTo?.subject!)!)
            if answerTo!.isEncrypted {
                if answerTo?.decryptedBody != nil {
                    textView.text.append("\n--------------------\n\n" + (answerTo?.decryptedBody)!)
                }
            } else {
                textView.text.append("\n--------------------\n\n" + (answerTo?.body)!) //textView.text.appendContentsOf("\n"+NSLocalizedString("original message", comment: "describing contents of the original message")+": \n\n"+(answerTo?.body)!)
            }
            textView.text = TextFormatter.insertBeforeEveryLine("> ", text: textView.text)
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
        imageView.tag = UIViewResolver.imageView.rawValue
        tableview.tag = UIViewResolver.tableview.rawValue
        toCollectionview.tag = UIViewResolver.toCollectionview.rawValue
        ccCollectionview.tag = UIViewResolver.ccCollectionview.rawValue
        subjectText.tag = UIViewResolver.subjectText.rawValue
        scrollview.tag = UIViewResolver.scrollview.rawValue

        updateNavigationBar()


        //LogHandler.printLogs()
        //LogHandler.deleteLogs()
        LogHandler.newLog()
        //LogHandler.printLogs()
        //---------------------------------------
        //Import private Key BEGIN
        /*
        let path = NSBundle.mainBundle().pathForResource("alice2005-private", ofType: "gpg")        //<---- Schlüsseldatei
        let pgp = ObjectivePGP.init()
        pgp.importKeysFromFile(path!, allowDuplicates: false)
        let enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
        do {
            let data = try pgp.keys[0].export()
            enc?.addKey(data, forMailAddresses: [])
        }
        catch _ {}
        */
        //Import private key END
        //---------------------------------------
        //---------------------------------------
        //Import public Key BEGIN
        /*
         let path = NSBundle.mainBundle().pathForResource("alice2005-public", ofType: "gpg")               //<---- Schlüsseldatei
         let pgp = ObjectivePGP.init()
         pgp.importKeysFromFile(path!, allowDuplicates: false)
         let enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
         do {
         let data = try pgp.keys[0].export()
         enc?.addKey(data, forMailAddresses: ["alice2005@web.de"])                           //<---- Emailadresse
         }
         catch _ {}
 */
        //Import public key END
        //---------------------------------------
        
        
        //---------------------------------------
        //ImportBobs Keys
        /*
         let path = NSBundle.mainBundle().pathForResource("bob2005", ofType: "asc")               //<---- Schlüsseldatei
         let pgp = ObjectivePGP.init()
         pgp.importKeysFromFile(path!, allowDuplicates: false)
         let enc = EnzevalosEncryptionHandler.getEncryption(EncryptionType.PGP)
         do {
         let data = try pgp.keys[0].export()
         enc?.addKey(data, forMailAddresses: ["bob2005@web.de"])                           //<---- Emailadresse
         }
         catch _ {}
        do {
            let data2 = try pgp.keys[1].export()
            enc?.addKey(data2, forMailAddresses: [])                           //<---- Emailadresse
        }
        catch _ {}
        */
        //Import public key END
        //---------------------------------------
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

    @IBAction func iconButtonPressed(_ sender: AnyObject) {
        iconButton(sender)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    @IBAction func tapped(_ sender: UITapGestureRecognizer) {
        //print(sender.description)
        //print(String(sender.view?.valueForKey("UILoggingName")))
        if LogHandler.logging {
            LogHandler.doLog(UIViewResolver.resolve((sender.view?.tag)!), interaction: "tap", point: sender.location(ofTouch: sender.numberOfTouches - 1, in: self.view), /*debugDescription: sender.view.debugDescription,*/ comment: "")
        }
    }

    @IBAction func panned(_ sender: UIPanGestureRecognizer) {
        if LogHandler.logging {
            if sender.state == .began {
                LogHandler.doLog(UIViewResolver.resolve((sender.view?.tag)!), interaction: "beginPan", point: sender.location(in: sender.view)/*CGPoint(x: 0,y: 0)*/, comment: String(describing: sender.translation(in: sender.view)))
            }
            if sender.state == .ended {
                LogHandler.doLog(UIViewResolver.resolve((sender.view?.tag)!), interaction: "endPan", point: sender.location(in: sender.view)/*CGPoint(x: 0,y: 0)*/, comment: String(describing: sender.translation(in: sender.view)))
            }
        }
    }

    @IBAction func swiped(_ sender: UISwipeGestureRecognizer) {
        if LogHandler.logging {
            LogHandler.doLog(UIViewResolver.resolve((sender.view?.tag)!), interaction: "swipe", point: sender.location(ofTouch: sender.numberOfTouches - 1, in: sender.view), comment: String(describing: sender.direction))
        }
    }

    @IBAction func rotated(_ sender: UIRotationGestureRecognizer) {
        if LogHandler.logging {
            LogHandler.doLog(UIViewResolver.resolve((sender.view?.tag)!), interaction: "rotate", point: CGPoint(x: 0, y: 0), comment: String(describing: sender.rotation))
        }
    }

    func tokenField(_ tokenField: VENTokenField, didChangeText text: String?) {
        if LogHandler.logging {
            LogHandler.doLog(UIViewResolver.resolve(subjectText.tag), interaction: "changeText", point: CGPoint(x: 0, y: 0), comment: subjectText.inputText()!)
        }
        if text == "log" {
            LogHandler.stopLogging()
            textView.text = LogHandler.getLogs()
            LogHandler.deleteLogs()
            LogHandler.newLog()
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        if LogHandler.logging {
            LogHandler.doLog(UIViewResolver.resolve(textView.tag), interaction: "changeText", point: CGPoint(x: 0, y: 0), comment: textView.text)
        }
    }
    
    func tokenFieldDidEndEditing(_ tokenField: VENTokenField) {}
    
    func reloadCollectionViews() {
        //toCollectionview.collectionViewLayout.invalidateLayout()
        toCollectionview.reloadData()//collectionViewLayout.invalidateLayout()
        ccCollectionview.reloadData()//collectionViewLayout.invalidateLayout()
        /*toCollectionviewHeight.constant += 200
        ccCollectionviewHeight.constant += 200
        toCollectionview.setNeedsDisplay()
        ccCollectionview.setNeedsDisplay()
        toCollectionviewHeight.constant -= 200
        ccCollectionviewHeight.constant -= 200
        toCollectionview.setNeedsDisplay()
        ccCollectionview.setNeedsDisplay()*/
        //toCollectionview.reloadItemsAtIndexPaths([NSIndexPath.init(forRow: collectionDataDelegate.collectionView(toCollectionview, numberOfItemsInSection: 0)-1, inSection: 0)])
        //toCollectionview.beginInteractiveMovementForItemAtIndexPath(NSIndexPath.init(forRow: collectionDataDelegate.collectionView(toCollectionview, numberOfItemsInSection: 0)-1, inSection: 0))
        //toCollectionview.collectionViewLayout.invalidateLayout()
        //toCollectionview.collectionViewLayout.finalizeCollectionViewUpdates()
    }
    
    func addFrequentCellIfPossible() {
        //collectionDataDelegate.alreadyInserted = (toText.mailTokens as NSArray as! [String])+(ccText.mailTokens as NSArray as! [String])
        //let len = collectionDataDelegate.collectionView(toCollectionview, numberOfItemsInSection: 0)
        //if len < CollectionDataDelegate.maxFrequent {
            //let path = NSIndexPath.init(forRow: len-1, inSection: 0)
            /*toCollectionview.performBatchUpdates({
                var indexes : [NSIndexPath] = []
                let len = self.collectionDataDelegate.collectionView(self.toCollectionview, numberOfItemsInSection: 0)
                print("benjamin ", len)
                var i = 0
                //for i in 1..<len {
                    indexes.append(NSIndexPath.init(forRow: i, inSection: 0))
                //}
                self.collectionDataDelegate.alreadyInserted = (self.toText.mailTokens as NSArray as! [String])+(self.ccText.mailTokens as NSArray as! [String])
                self.toCollectionview.insertItemsAtIndexPaths(indexes)
                }, completion: nil)*/
            //toCollectionview.insertItemsAtIndexPaths([path])
        //}
        collectionDataDelegate.alreadyInserted = (toText.mailTokens as NSArray as! [String])+(ccText.mailTokens as NSArray as! [String])
        toCollectionview.reloadData()
        //toCollectionviewHeight.trans
        //        toCollectionview.translatesAutoresizingMaskIntoConstraints = true
        //toCollectionview.startInteractiveTransitionToCollectionViewLayout(toCollectionview.collectionViewLayout, completion: nil)
        toCollectionview.reloadData()
        ccCollectionview.reloadData()
    }
    
    func showContact(_ email: String) {
        let records = DataHandler.handler.getContactByAddress(email).records
        for r in records {
            for address in r.addresses {
                if address.mailAddress == email && address.prefEnc == r.hasKey {
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
            if let sender = sender {
                destinationVC.keyRecord = (sender["record"] as! KeyRecord)
                destinationVC.highlightEmail = (sender["email"] as! String)
            }
        }
    }

    func editName(_ tokenField: VENTokenField) {
        if let inText = tokenField.inputText() {
            if LogHandler.logging {
                LogHandler.doLog(UIViewResolver.resolve(tokenField.tag), interaction: "changeText", point: CGPoint(x: 0, y: 0), comment: inText)
            }
            if inText != "" {
                scrollview.isScrollEnabled = false
                scrollview.contentOffset = CGPoint(x: 0, y: tokenField.frame.origin.y - self.topLayoutGuide.length)
                //print(tokenField.frame.origin.y, " ", tokenField.frame.maxY)
                tableviewBegin.constant = tokenField.frame.maxY - tokenField.frame.origin.y
                tableviewHeight.constant = keyboardY - tableviewBegin.constant - (self.navigationController?.navigationBar.frame.maxY)!
                searchContacts(inText)
            } else {
                scrollview.isScrollEnabled = true
                tableviewHeight.constant = 0
                if tokenField == toText {
                    //toCollectionviewHeight.constant = 100
                } else {
                    //ccCollectionviewHeight.constant = 100
                }
            }
        }
    }

    func insertName(_ name: String, address: String) {
        if toText.isFirstResponder {
            toText.delegate?.tokenField!(toText, didEnterText: name, mail: address)
            if LogHandler.logging {
                LogHandler.doLog(UIViewResolver.resolve(toText.tag), interaction: "insert", point: CGPoint(x: 0, y: Int((toText.dataSource?.numberOfTokens!(in: toText))!)), comment: name + " " + address)
            }
        } else if ccText.isFirstResponder {
            ccText.delegate?.tokenField!(ccText, didEnterText: name, mail: address)
            if LogHandler.logging {
                LogHandler.doLog(UIViewResolver.resolve(ccText.tag), interaction: "insert", point: CGPoint(x: 0, y: Int((ccText.dataSource?.numberOfTokens!(in: ccText))!)), comment: name + " " + address)
            }
        }
    }

    func searchContacts(_ prefix: String) {
        AppDelegate.getAppDelegate().requestForAccess({ access in
            //print(access)
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
                print("exception")
            }
            //print("contacts done")
        } else {
            print("no Access!")
        }
    }

    func doContact() {
        AppDelegate.getAppDelegate().requestForAccess({ access in
            print(access)
        })
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        if authorizationStatus == CNAuthorizationStatus.authorized {
            do {
                print(try AppDelegate.getAppDelegate().contactStore.unifiedContacts(matching: CNContact.predicateForContacts(matchingName: "o"), keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor]))
            }
            catch {
                print("exception")
            }
            print("contacts done")
        } else {
            print("no Access!")
        }
    }
    
    func newInput(_ tokenField: VENTokenField){
        print("input")
        animateIfNeeded()

        collectionDataDelegate.alreadyInserted = (toText.mailTokens as NSArray as! [String]) + (ccText.mailTokens as NSArray as! [String])
        toCollectionview.reloadData()
//        toCollectionview.translatesAutoresizingMaskIntoConstraints = true
        //toCollectionview.startInteractiveTransitionToCollectionViewLayout(toCollectionview.collectionViewLayout, completion: nil)
        toCollectionview.setNeedsLayout()
        toCollectionview.setNeedsDisplay()
//        toCollectionview.translatesAutoresizingMaskIntoConstraints = false
        toCollectionview.reloadData()
        //let path = NSIndexPath.init(forRow: collectionDataDelegate.collectionView(toCollectionview, numberOfItemsInSection: 0)-1, inSection: 0)
        //toCollectionview.reloadItemsAtIndexPaths([path])
        //toCollectionview.reloadData()
        //toCollectionview.collectionViewLayout.prepareLayout()// .invalidateLayout()
        //ccCollectionview.collectionViewLayout.prepareLayout()//.invalidateLayout()
        //toCollectionview.invalidateIntrinsicContentSize()
        //toCollectionview.updateConstraints()
        
        //reloadCollectionViews()
    }

    func keyboardOpen(_ notification: Notification) {
        //if reducedSize == 0{
        LogHandler.doLog("keyboard", interaction: "open", point: CGPoint(x: 0, y: 0), comment: "")
        var info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        reducedSize = keyboardFrame.size.height

        keyboardY = keyboardFrame.origin.y
        //print("keyboard ", keyboardY)

        if toText.isFirstResponder {
            toCollectionview.reloadData()
            UIView.animate(withDuration: 2.5, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: { self.toCollectionviewHeight.constant = 100 }, completion: nil)
        }
        if ccText.isFirstResponder {
            ccCollectionviewHeight.constant = 100
            ccCollectionview.reloadData()
        }
        if !toText.isFirstResponder {
            UIView.animate(withDuration: 2.5, animations: { () -> Void in self.toCollectionviewHeight.constant = 0 })
        }
        if !ccText.isFirstResponder {
            ccCollectionviewHeight.constant = 0
        }

        UIView.animate(withDuration: 0.1, animations: { () -> Void in

            let contentInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0.0, self.reducedSize, 0.0)
            self.scrollview!.contentInset = contentInsets
        })
    }

    func keyboardClose(_ notification: Notification) {
        LogHandler.doLog("keyboard", interaction: "close", point: CGPoint(x: 0, y: 0), comment: "")
        if reducedSize != 0 {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.reducedSize = 0
                let contentInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0.0, self.reducedSize, 0.0)
                self.scrollview!.contentInset = contentInsets
            })
            if !toText.isFirstResponder {
                toCollectionviewHeight.constant = 0
            }
            if !ccText.isFirstResponder {
                ccCollectionviewHeight.constant = 0
            }
        }
    }

    func iconButton(_ sender: AnyObject) {
        //print(sender.absoluteString)
        //print(recognizer.locationOfTouch(recognizer.numberOfTouches()-1, inView: imageView))
        /*for var i in 1 ..< recognizer.numberOfTouches(){
         print(recognizer.locationOfTouch(i, inView: self.view))
         }*/
        let m = self.secureState
        let alert: UIAlertController
        let url: String
        if !m {
            alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "Postcard label"), message: NSLocalizedString("SendInsecureInfo", comment: "Postcard infotext"), preferredStyle: .alert)
            url = "https://enzevalos.org/infos/postcard"
        } else {
            alert = UIAlertController(title: NSLocalizedString("Letter", comment: "Letter label"), message: NSLocalizedString("SendSecureInfo", comment: "Letter infotext"), preferredStyle: .alert)
            url = "https://enzevalos.org/infos/letter"
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("MoreInformation", comment: "More Information label"), style: .default, handler: { (action: UIAlertAction!) -> Void in UIApplication.shared.openURL(URL(string: url)!) }))
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
        })
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
            alert = UIAlertController(title: NSLocalizedString("discard", comment: "discard"), message: NSLocalizedString("discardText", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "cancel"), style: .cancel, handler: { (action: UIAlertAction!) -> Void in
                firstResponder?.becomeFirstResponder()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("discardButton", comment: "discard"), style: .destructive, handler: { (action: UIAlertAction!) -> Void in
                self.navigationController?.dismiss(animated: true, completion: nil)
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

        mailHandler.send(toEntrys as NSArray as! [String], ccEntrys: ccEntrys as NSArray as! [String], bccEntrys: [], subject: subject, message: message, callback: self.mailSend)
    }

    func mailSend(_ error: NSError?) {
        if (error != nil) {
            NSLog("Error sending email: \(error)")
            AppDelegate.getAppDelegate().showMessage("An error occured", completion: nil)
        } else {
            NSLog("Send successful!")
            if (self.answerTo != nil) {
                AppDelegate.getAppDelegate().mailHandler.addFlag((self.answerTo?.uid)!, flags: MCOMessageFlag.answered)
            }
            //AppDelegate.getAppDelegate().showMessage("Send successfully", completion: self.sendCompleted)
            self.sendCompleted()
        }
    }

    func sendCompleted() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    func getContemporarySecurityState() -> Bool {
        toSecure = toText.dataSource!.isSecure!(toText) //TODO: Add pref enc field.
        ccSecure = ccText.dataSource!.isSecure!(ccText)
        return toSecure && ccSecure
    }

    func updateNavigationBar() {
        if(getContemporarySecurityState()) {
            self.navigationController?.navigationBar.barTintColor = ThemeManager.encryptedMessageColor()
        } else {
            self.navigationController?.navigationBar.barTintColor = ThemeManager.uncryptedMessageColor()
        }
    }

    // TODO: remove if not necessary anymore
    //    func animateIfNeeded(secure : Bool){
    //        if secure != self.secureState {
    //            setAnimation(secure)
    //            if secure {
    //                imageView.image = UIImage(named: "Icon_animated001-001_alpha_verschoben-90.png")!
    //            }
    //            else {
    //                imageView.image = UIImage(named: "Icon_animated001-007_alpha_verschoben-90.png")!
    //            }
    //            imageView.startAnimating()
    //            self.secureState = secure
    //        }
    //    }

    func animateIfNeeded() {
        let contemporarySecureState = getContemporarySecurityState()
        if (contemporarySecureState) != self.secureState {
            if(ThemeManager.animation()) {
                setAnimation()
                if contemporarySecureState {
                    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                        self.navigationController?.navigationBar.barTintColor = ThemeManager.encryptedMessageColor()
                    }, completion: nil)
                } else {
                    UIView.animate(withDuration: 0.5, delay: 0, options: [UIViewAnimationOptions.curveEaseIn/*, UIViewAnimationOptions.Autoreverse*/], animations: {
                        self.navigationController?.navigationBar.barTintColor = ThemeManager.uncryptedMessageColor()
                    }, completion: { (_: Bool) in
                        sleep(1)
                        UIView.animate(withDuration: 0.5, delay: 1.5, options: UIViewAnimationOptions.curveEaseIn, animations: {
                            self.navigationController?.navigationBar.barTintColor = ThemeManager.uncryptedMessageColor()
                        }, completion: nil)
                    })
                    /*UIView.animateWithDuration(0.5, delay: 1.5, options: UIViewAnimationOptions.CurveEaseIn ,animations: {
                     self.navigationController?.navigationBar.barTintColor = UIColor.groupTableViewBackgroundColor()
                     }, completion: nil)*/
                }
                imageView.startAnimating()
            }
        }
        updateNavigationBar()
        self.secureState = getContemporarySecurityState()
    }

    func setAnimation() {
        if let view = iconButton.subviews.first as? AnimatedSendIcon {
            view.switchIcons()
        }
    }
}

