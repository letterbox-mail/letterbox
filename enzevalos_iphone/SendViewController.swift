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

class SendViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate, VENTokenFieldDelegate{
    
    var imageView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 5, width: 200, height: 45))
    @IBOutlet weak var button: UIBarButtonItem!
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
    var keyboardY : CGFloat = 0
    var reducedSize : CGFloat = 0
    var secureState = true
    var toSecure = true
    var ccSecure = true
    var dataDelegate = VENDataDelegate()
    var mailHandler = MailHandler()
    var tableDataDelegate = TableViewDataDelegate(insertCallback: {(name : String, address : String) -> Void in return})
    var collectionDataDelegate = CollectionDataDelegate(suggestionFunc: AddressHandler.frequentAddresses, insertCallback: {(name : String, address : String) -> Void in return})
    var recognizer : UIGestureRecognizer = UIGestureRecognizer.init()
    
    var answerTo: Mail? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        dataDelegate = VENDataDelegate(changeFunc: self.editName)
        tableDataDelegate = TableViewDataDelegate(insertCallback: self.insertName)
        collectionDataDelegate = CollectionDataDelegate(suggestionFunc: AddressHandler.frequentAddresses, insertCallback: self.insertName)
        imageView.contentMode = .ScaleAspectFit
        imageView.image = UIImage(named: "Icon_animated001-001_alpha_verschoben-90")!
        setAnimation(false)
        self.navigationItem.titleView = imageView
        //recognizer = UIGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        //self.view.addGestureRecognizer(recognizer)
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.iconButton(_:))))
        imageView.userInteractionEnabled = true
        
        textView.delegate = self
        textView.font = UIFont.systemFontOfSize(17)
        textView.text = ""
        
        subjectText.toLabelText = NSLocalizedString("Subject", comment: "subject label")+": "
        
        toText.delegate = dataDelegate
        toText.dataSource = dataDelegate
        toText.inputTextFieldKeyboardType = UIKeyboardType.EmailAddress
        toText.toLabelText = NSLocalizedString("To", comment: "to label")+": "
        toCollectionview.delegate = collectionDataDelegate
        toCollectionview.dataSource = collectionDataDelegate
        toCollectionview.registerNib(UINib(nibName: "FrequentCell", bundle: nil), forCellWithReuseIdentifier: "frequent")
        toCollectionviewHeight.constant = 0
        ccText.delegate = dataDelegate
        ccText.dataSource = dataDelegate
        ccText.toLabelText = NSLocalizedString("Cc", comment: "copy label")+": "
        ccCollectionview.delegate = collectionDataDelegate
        ccCollectionview.dataSource = collectionDataDelegate
        ccCollectionview.registerNib(UINib(nibName: "FrequentCell", bundle: nil), forCellWithReuseIdentifier: "frequent")
        ccCollectionviewHeight.constant = 0
        
        subjectText.delegate = self
        
        //will always be thrown, when a token was editied
        toText.addTarget(self, action: #selector(self.newInput(_:)), forControlEvents: UIControlEvents.EditingDidEnd)
        ccText.addTarget(self, action: #selector(self.newInput(_:)), forControlEvents: UIControlEvents.EditingDidEnd)
        
        //toText.delegate?.tokenField!(toText, didEnterText: "jakob.bode@fu-berlin.de")
        if answerTo != nil {
            toText.delegate?.tokenField!(toText, didEnterText: (answerTo?.sender?.mailbox!)!)
            for r in (answerTo?.receivers)!{
                if r.mailbox! != mailHandler.useraddr{
                    ccText.delegate?.tokenField!(ccText, didEnterText: r.mailbox!)
                }
            }
            subjectText.setText(NSLocalizedString("Re", comment: "prefix for subjects of answered mails")+": "+(answerTo?.subject!)!)
            textView.text = NSLocalizedString("mail from", comment: "describing who send the mail")+" "
            textView.text.appendContentsOf((answerTo?.sender?.mailbox!)!)
            textView.text.appendContentsOf(" "+NSLocalizedString("sent at", comment: "describing when the mail was send")+" "+(answerTo?.timeString)!)
            textView.text.appendContentsOf("\n"+NSLocalizedString("to", comment: "describing adressee")+": ")
            textView.text.appendContentsOf(mailHandler.useraddr)
            if ccText.mailTokens.count > 0 {
                textView.text.appendContentsOf(", ")
            }
            textView.text.appendContentsOf(ccText.mailTokens.componentsJoinedByString(", "))
            textView.text.appendContentsOf("\n"+NSLocalizedString("subject", comment:"describing what subject was choosen")+": "+(answerTo?.subject!)!)
            if answerTo!.isEncrypted {
                answerTo?.decryptIfPossible()
                if answerTo?.decryptedBody != nil {
                    textView.text.appendContentsOf("\n--------------------\n\n"+(answerTo?.decryptedBody)!)
                }
            }
            else {
                textView.text.appendContentsOf("\n--------------------\n\n"+(answerTo?.body)!) //textView.text.appendContentsOf("\n"+NSLocalizedString("original message", comment: "describing contents of the original message")+": \n\n"+(answerTo?.body)!)
            }
            textView.text = TextFormatter.insertBeforeEveryLine("> ", text: textView.text)
        }
        
        let sepConst:CGFloat = 1/UIScreen.mainScreen().scale
        seperator1Height.constant = sepConst//0.5
        seperator2Height.constant = sepConst//0.5
        seperator3Height.constant = sepConst//0.5
        
        
        seperator1Leading.constant += toText.horizontalInset
        seperator2Leading.constant += ccText.horizontalInset
        seperator3Leading.constant += subjectText.horizontalInset
        
        textViewLeading.constant = seperator3Leading.constant-4
    
        ccText.inputTextFieldKeyboardType = UIKeyboardType.EmailAddress
        scrollview.clipsToBounds = true
        
        tableview.delegate = tableDataDelegate
        tableview.dataSource = tableDataDelegate
        tableview.registerNib(UINib(nibName: "ContactCell", bundle: nil), forCellReuseIdentifier: "contacts")
        tableviewHeight.constant = 0
        
        
        let indexPath = NSIndexPath()
        tableview.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        
        //register KeyBoardevents
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardOpen(_:)), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardClose(_:)), name:UIKeyboardWillHideNotification, object: nil);
        
        toText.tag = UIViewResolver.toText.rawValue
        ccText.tag = UIViewResolver.ccText.rawValue
        textView.tag = UIViewResolver.textView.rawValue
        imageView.tag = UIViewResolver.imageView.rawValue
        tableview.tag = UIViewResolver.tableview.rawValue
        toCollectionview.tag = UIViewResolver.toCollectionview.rawValue
        ccCollectionview.tag = UIViewResolver.ccCollectionview.rawValue
        subjectText.tag = UIViewResolver.subjectText.rawValue
        scrollview.tag = UIViewResolver.scrollview.rawValue
        
        
        //LogHandler.printLogs()
        //LogHandler.deleteLogs()
        LogHandler.newLog()
        //LogHandler.printLogs()
        
        //LogHandler.printLogs()
        //var handler = CryptoHandler.getHandler() // <----
        //handler.pgp.importKeysFromFile("alice2005-2.gpg", allowDuplicates: false)
        
        //var pubKey = "-----BEGIN PUBLIC KEY-----\n"+"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmET/fC2VqlTBg0X4 0TR\n"+"obDFsWQAdAXYDYnYEa83H6pzex5Wg E/0 YKV5n9fh4NsO1ma1yMAJ3MIBnr9PuL\n"+"yI/67rqXd5YJENgtDIUHMr85CzW6UJIelVIf3QXMc7vbWXSLVbeX5mCNc8pQ5QPr\n"+"fmFgHeqGQR7pRKYP4humJHjexW4fJbz774KgL4nzskGAxGBSY6VC9s7xlXJB99w7\n"+"xXMPu2ZwEDNjqukK2lxx3EvhX8HvmueA0kU0Hf/7XLyp2lF/GiD3ZE/yNRcrh50\n"+"AXwP34U7lv2NEv/oUTOocFlOte iaUXvdYx1UZPFdaJD/asnjcerSdqqfXS8LN55\n"+"zQIDAQAB\n"+"-----END PUBLIC KEY-----"
        
        //var url = NSURL.fileURLWithPath("alice2005-2.gpg")
        //let path = NSBundle.mainBundle().pathForResource("alice2005-2", ofType: "gpg")
        //let path = NSBundle.mainBundle().pathForResource("alice2005-private", ofType: "gpg") // <---- PRIVATE
        //var path = NSBundle.mainBundle().pathForResource("JakobBode", ofType: "asc")    // <----
        //var url = NSBundle.mainBundle().URLForResource("test", withExtension: "")
        //print("url",url)
        
        
        //var data = "Hallo".dataUsingEncoding(NSUTF8StringEncoding)
        //print("data",data)
        /*do {
            try data?.writeToURL(url!, options: NSDataWritingOptions.AtomicWrite)
        } catch var c {
            print(c)
        }*/
        
        //print("content",NSData(contentsOfURL: url!))
        //print(url.absoluteString)
        //print(path)
        
        //handler.pgp.importKeysFromFile(path!, allowDuplicates: false)
        
        
        //path = NSBundle.mainBundle().pathForResource("jabo", ofType: "asc")
        //handler.pgp.importKeysFromFile(path!, allowDuplicates: false)   // <----
        //KeyHandler.createHandler().reset("spam_jabo@web.de")
        //KeyHandler.createHandler().addKey(handler.pgp.keys[0])          // <----
        //KeyHandler.createHandler().addPrivateKey(handler.pgp.keys[0])   // <---- PRIVATE
        //print(KeyHandler.createHandler().getKeyByAddr("jakob.bode@fu-berlin.de"))     // <----
        /*KeyHandler.createHandler().resetPrivateKey()
        print(KeyHandler.createHandler().getPrivateKey())
        KeyHandler.createHandler().resetPrivateKey()
        print(KeyHandler.createHandler().getPrivateKey())
        KeyHandler.createHandler().resetPrivateKey()
        print(KeyHandler.createHandler().getPrivateKey())
        KeyHandler.createHandler().resetPrivateKey()*/
        //print(KeyHandler.createHandler().getPrivateKey()) // <---- PRIVATE
        /*do {
            textView.text = String(data: try handler.pgp.encryptData("Hallo Welt".dataUsingEncoding(NSUTF8StringEncoding)!, usingPublicKeys: handler.pgp.keys, armored: true), encoding: NSUTF8StringEncoding)
        } catch _ {
        
        }*/
        //print(handler.pgp.importKeysFromData(pubKey.dataUsingEncoding(NSUTF8StringEncoding)!, allowDuplicates: false))
        
        //print(handler.pgp.importKeysFromData("-----BEGIN PUBLIC KEY-----MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmET/fC2VqlTBg0X4 0TRobDFsWQAdAXYDYnYEa83H6pzex5Wg E/0 YKV5n9fh4NsO1ma1yMAJ3MIBnr9PuLyI/67rqXd5YJENgtDIUHMr85CzW6UJIelVIf3QXMc7vbWXSLVbeX5mCNc8pQ5QPrfmFgHeqGQR7pRKYP4humJHjexW4fJbz774KgL4nzskGAxGBSY6VC9s7xlXJB99w7xXMPu2ZwEDNjqukK2lxx3EvhX8HvmueA0kU0Hf/7XLyp2lF/GiD3ZE/yNRcrh50AXwP34U7lv2NEv/oUTOocFlOte iaUXvdYx1UZPFdaJD/asnjcerSdqqfXS8LN55zQIDAQAB-----END PUBLIC KEY-----".dataUsingEncoding(NSUTF8StringEncoding)!, allowDuplicates: false))
        
        
        //print(handler.pgp.getKeysForUserID("Alice Bob <alice2005@web.de>"))
        
        
        //print(handler.pgp.getKeysOfType(PGPKeyType.Public))
        //print(handler.pgp.keys)
        
        /*let keychain = Keychain()
        var data = try? keychain.getData("spam_jabo@web.de-index")
        print(keychain[attributes: "spam_jabo@web.de-index"]?.creationDate)
        var index: Int = 0*/
        /*do {
            try keychain.set(NSData(bytes: &index, length: sizeof(Int)), key: "spam_jabo@web.de-index")
        }
        catch let error {
            print(error)
        }*/
        /*data = try? keychain.getData("spam_jabo@web.de-index")
        print(keychain[attributes: "spam_jabo@web.de-index"]?.creationDate)
        print(data!)
        data!!.getBytes(&index, length: sizeof(Int))
        print(index)
        do{
            var data = try? handler.pgp.keys[0].export()
            //print(data)
            print(handler.pgp.keysFromData(data!))
        }
        catch _ {
            
        }
        var coder = NSCoder()
        coder.encodeObject(handler.pgp.keys[0], forKey: "test")
        print(coder.decodeObjectForKey("test") as! PGPKey)*/
        //KeyHandler.createHandler().addKey(handler.pgp.keys[0])
        
        //print(pubKey.dataUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    override func viewDidAppear(animated: Bool){
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func tapped(sender: UITapGestureRecognizer) {
        //print(sender.description)
        //print(String(sender.view?.valueForKey("UILoggingName")))
        if LogHandler.logging {
            LogHandler.doLog(UIViewResolver.resolve((sender.view?.tag)!), interaction: "tap", point: sender.locationOfTouch(sender.numberOfTouches()-1, inView: self.view), /*debugDescription: sender.view.debugDescription,*/ comment: "")
        }
        
    }
    
    @IBAction func panned(sender: UIPanGestureRecognizer) {
        if LogHandler.logging {
            if sender.state == .Began{
                LogHandler.doLog(UIViewResolver.resolve((sender.view?.tag)!), interaction: "beginPan", point: sender.locationInView(sender.view)/*CGPoint(x: 0,y: 0)*/, comment: String(sender.translationInView(sender.view)))
            }
            if sender.state == .Ended{
                LogHandler.doLog(UIViewResolver.resolve((sender.view?.tag)!), interaction: "endPan", point: sender.locationInView(sender.view)/*CGPoint(x: 0,y: 0)*/, comment: String(sender.translationInView(sender.view)))
            }
        }
    }
    
    @IBAction func swiped(sender: UISwipeGestureRecognizer) {
        if LogHandler.logging {
            LogHandler.doLog(UIViewResolver.resolve((sender.view?.tag)!), interaction: "swipe", point: sender.locationOfTouch(sender.numberOfTouches()-1, inView: sender.view), comment: String(sender.direction))
        }
    }
    
    @IBAction func rotated(sender: UIRotationGestureRecognizer) {
        if LogHandler.logging {
            LogHandler.doLog(UIViewResolver.resolve((sender.view?.tag)!), interaction: "rotate", point: CGPoint(x: 0, y: 0), comment: String(sender.rotation))
        }
    }
    
    func tokenField(tokenField: VENTokenField, didChangeText text: String?) {
        if LogHandler.logging {
            LogHandler.doLog(UIViewResolver.resolve(subjectText.tag), interaction: "changeText", point: CGPoint(x:0, y:0), comment: subjectText.inputText()!)
        }
        if text == "log"{
                LogHandler.stopLogging()
                textView.text = LogHandler.getLogs()
                LogHandler.deleteLogs()
                LogHandler.newLog()
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        if LogHandler.logging{
            LogHandler.doLog(UIViewResolver.resolve(textView.tag), interaction: "changeText", point: CGPoint(x: 0,y: 0), comment: textView.text)
        }
    }
    
    func tokenFieldDidEndEditing(tokenField: VENTokenField) {}
    
    /*func tapped(sender: AnyObject){
        print("anything")
    }*/
    
    func editName(tokenField : VENTokenField){
        if let inText = tokenField.inputText(){
            if LogHandler.logging {
                LogHandler.doLog(UIViewResolver.resolve(tokenField.tag), interaction: "changeText", point: CGPoint(x:0, y:0), comment: inText)
            }
            if inText != "" {
                scrollview.scrollEnabled = false
                scrollview.contentOffset = CGPoint(x: 0, y: tokenField.frame.origin.y-self.topLayoutGuide.length)
                //print(tokenField.frame.origin.y, " ", tokenField.frame.maxY)
                tableviewBegin.constant = tokenField.frame.maxY-tokenField.frame.origin.y
                tableviewHeight.constant = keyboardY - tableviewBegin.constant - (self.navigationController?.navigationBar.frame.maxY)!
                searchContacts(inText)
            }
            else {
                scrollview.scrollEnabled = true
                tableviewHeight.constant = 0
                if tokenField == toText {
//toCollectionviewHeight.constant = 100
                }
                else {
                    //ccCollectionviewHeight.constant = 100
                }
            }
        }
    }
    
    func insertName(name : String, address : String) {
        if toText.isFirstResponder(){
            toText.delegate?.tokenField!(toText, didEnterText: name, mail: address)
            if LogHandler.logging {
                LogHandler.doLog(UIViewResolver.resolve(toText.tag), interaction: "insert", point: CGPoint(x: 0, y: Int((toText.dataSource?.numberOfTokensInTokenField!(toText))!)), comment: name+" "+address)
            }
        }
        else if ccText.isFirstResponder(){
            ccText.delegate?.tokenField!(ccText, didEnterText: name, mail: address)
            if LogHandler.logging {
                LogHandler.doLog(UIViewResolver.resolve(ccText.tag), interaction: "insert", point: CGPoint(x: 0, y: Int((ccText.dataSource?.numberOfTokensInTokenField!(ccText))!)), comment: name+" "+address)
            }
        }
    }
    
    func searchContacts(prefix: String){
        AppDelegate.getAppDelegate().requestForAccess({access in
            //print(access)
        })
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        if authorizationStatus == CNAuthorizationStatus.Authorized {
            do {
                let contacts = try AppDelegate.getAppDelegate().contactStore.unifiedContactsMatchingPredicate(CNContact.predicateForContactsMatchingName(prefix), keysToFetch: [CNContactFormatter.descriptorForRequiredKeysForStyle(CNContactFormatterStyle.FullName), CNContactEmailAddressesKey, CNContactImageDataKey, CNContactThumbnailImageDataKey])
                var indexes : [NSIndexPath] = []
                var i = 0
                for (i=0; i<tableview.numberOfRowsInSection(0); i+=1) {
                    indexes.append(NSIndexPath.init(forRow: i, inSection: 0))
                }
                indexes = []
                tableDataDelegate.contacts = []
                tableDataDelegate.addresses = []
                tableDataDelegate.pictures = []
                for c in contacts {
                    for mail in c.emailAddresses {
                        if let name = CNContactFormatter.stringFromContact(c, style: .FullName){
                            self.tableDataDelegate.contacts.append(name)
                        }
                        else {
                            self.tableDataDelegate.contacts.append(c.givenName+c.familyName)
                        }
                        self.tableDataDelegate.addresses.append(mail.value as! String)
                        self.tableDataDelegate.pictures.append(c.getImageOrDefault())
                    }
                }
                indexes = []
                for (i=tableDataDelegate.contacts.count; i < tableview.numberOfRowsInSection(0); i+=1){
                    indexes.append(NSIndexPath.init(forRow: i, inSection: 0))
                    if i+1 == tableview.numberOfRowsInSection(0) {
                            tableview.deleteRowsAtIndexPaths(indexes, withRowAnimation: UITableViewRowAnimation.None)
                    }
                }
                for (i=tableview.numberOfRowsInSection(0); i < tableDataDelegate.contacts.count; i+=1){
                    indexes.append(NSIndexPath.init(forRow: i, inSection: 0))
                    if i+1 == tableDataDelegate.contacts.count {
                        tableview.insertRowsAtIndexPaths(indexes, withRowAnimation: UITableViewRowAnimation.None)
                    }
                }
                tableview.reloadData()
            }
            catch {
                print("exception")
            }
            //print("contacts done")
        }
        else {
            print("no Access!")
        }

    }
    
    func doContact(){
        AppDelegate.getAppDelegate().requestForAccess({access in
            print(access)
        })
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        if authorizationStatus == CNAuthorizationStatus.Authorized {
            do {
                print(try AppDelegate.getAppDelegate().contactStore.unifiedContactsMatchingPredicate(CNContact.predicateForContactsMatchingName("o"), keysToFetch: [CNContactGivenNameKey]) )
            }
            catch {
                print("exception")
            }
            print("contacts done")
        }
        else {
            print("no Access!")
        }
    }
    
    func newInput(tokenField: VENTokenField){
        animateIfNeeded()
        collectionDataDelegate.alreadyInserted = (toText.mailTokens as NSArray as! [String])+(ccText.mailTokens as NSArray as! [String])
        toCollectionview.reloadData()
        ccCollectionview.reloadData()
    }
   
    
    func keyboardOpen(notification: NSNotification) {
        //if reducedSize == 0{
        LogHandler.doLog("keyboard", interaction: "open", point: CGPoint(x: 0,y: 0), comment: "")
            var info = notification.userInfo!
            let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            reducedSize = keyboardFrame.size.height
        
            keyboardY = keyboardFrame.origin.y
            //print("keyboard ", keyboardY)
        
        if toText.isFirstResponder() {
            toCollectionview.reloadData()
            UIView.animateWithDuration(2.5, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: {self.toCollectionviewHeight.constant = 100}, completion: nil)
        }
        if ccText.isFirstResponder() {
            ccCollectionviewHeight.constant = 100
            ccCollectionview.reloadData()
        }
        if !toText.isFirstResponder() {
            UIView.animateWithDuration(2.5, animations: { () -> Void in self.toCollectionviewHeight.constant = 0})
        }
        if !ccText.isFirstResponder() {
            ccCollectionviewHeight.constant = 0
        }
        
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                let contentInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0.0, self.reducedSize, 0.0)
                self.scrollview!.contentInset = contentInsets
            })
    }
    
    func keyboardClose(notification: NSNotification) {
        LogHandler.doLog("keyboard", interaction: "close", point: CGPoint(x: 0,y: 0), comment: "")
        if reducedSize != 0{
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                self.reducedSize = 0
                let contentInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0.0, self.reducedSize, 0.0)
                self.scrollview!.contentInset = contentInsets
            })
            if !toText.isFirstResponder() {
                toCollectionviewHeight.constant = 0
            }
            if !ccText.isFirstResponder() {
                ccCollectionviewHeight.constant = 0
            }
        }
    }
    
    func iconButton(sender: AnyObject) {
        //print(sender.absoluteString)
        //print(recognizer.locationOfTouch(recognizer.numberOfTouches()-1, inView: imageView))
        /*for var i in 1 ..< recognizer.numberOfTouches(){
            print(recognizer.locationOfTouch(i, inView: self.view))
        }*/
        let m = self.secureState
        let alert: UIAlertController
        let url: String
        if !m {
            alert = UIAlertController(title: NSLocalizedString("Postcard", comment: "Postcard label"), message: NSLocalizedString("SendInsecureInfo", comment: "Postcard infotext"), preferredStyle: UIAlertControllerStyle.Alert)
            url = "https://enzevalos.org/infos/postcard"
        } else {
            alert = UIAlertController(title: NSLocalizedString("Letter", comment: "Letter label"), message: NSLocalizedString("SendSecureInfo", comment: "Letter infotext"), preferredStyle: UIAlertControllerStyle.Alert)
            url = "https://enzevalos.org/infos/letter"
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("MoreInformation", comment: "More Information label"), style: UIAlertActionStyle.Default, handler: {(action:UIAlertAction!) -> Void in UIApplication.sharedApplication().openURL(NSURL(string: url)!)}))
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        dispatch_async(dispatch_get_main_queue(), {
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }
    
    @IBAction func pressCancel(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func pressSend(sender: AnyObject) {
        let toEntrys = toText.mailTokens
        let ccEntrys = ccText.mailTokens
        let subject = subjectText.inputText()!
        let message = textView.text!
        
        mailHandler.send(toEntrys as NSArray as! [String], ccEntrys: ccEntrys as NSArray as! [String], bccEntrys: [] , subject: subject , message: message, callback: self.mailSend)
    }
    
    func mailSend(error : NSError?){
        if (error != nil) {
            NSLog("Error sending email: \(error)")
            AppDelegate.getAppDelegate().showMessage("An error occured")
        } else {
            NSLog("Send!")
            if (self.answerTo != nil) {
                AppDelegate.getAppDelegate().mailHandler.addFlag(UInt64((self.answerTo?.uid)!), flags: MCOMessageFlag.Answered)
            }
            AppDelegate.getAppDelegate().showMessage("Send successfully")
        }
    }
    
    
    func animateIfNeeded(secure : Bool){
        if secure != self.secureState {
            setAnimation(secure)
            if secure {
                imageView.image = UIImage(named: "Icon_animated001-001_alpha_verschoben-90.png")!
            }
            else {
                imageView.image = UIImage(named: "Icon_animated001-007_alpha_verschoben-90.png")!
            }
            imageView.startAnimating()
            self.secureState = secure
        }
    }
    
    func animateIfNeeded(){
        toSecure = toText.dataSource!.isSecure!(toText)
        ccSecure = ccText.dataSource!.isSecure!(ccText)
        if (toSecure && ccSecure) != self.secureState {
            setAnimation()
            if toSecure && ccSecure {
                imageView.image = UIImage(named: "Icon_animated001-001_alpha_verschoben-90.png")!
                UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseIn ,animations: {
                    self.navigationController?.navigationBar.barTintColor = UIColor.groupTableViewBackgroundColor()
                    }, completion: nil)
            }
            else {
                imageView.image = UIImage(named: "Icon_animated001-007_alpha_verschoben-90.png")!
                UIView.animateWithDuration(0.5, delay: 0, options: [UIViewAnimationOptions.CurveEaseIn/*, UIViewAnimationOptions.Autoreverse*/] ,animations: {
                    self.navigationController?.navigationBar.barTintColor = UIColor.orangeColor()//UIColor.init(red: 1, green: 0.7, blue: 0.5, alpha: 1)
                    }, completion: {(_ : Bool) in
                        print("orange!!!!!!!!!")
                        sleep(1)
                        UIView.animateWithDuration(0.5, delay: 1.5, options: UIViewAnimationOptions.CurveEaseIn ,animations: {
                            self.navigationController?.navigationBar.barTintColor = UIColor.groupTableViewBackgroundColor()
                            }, completion: nil)
                })
                /*UIView.animateWithDuration(0.5, delay: 1.5, options: UIViewAnimationOptions.CurveEaseIn ,animations: {
                    self.navigationController?.navigationBar.barTintColor = UIColor.groupTableViewBackgroundColor()
                    }, completion: nil)*/
            }
            imageView.startAnimating()
            self.secureState = toSecure && ccSecure
        }
    }
    
    func setAnimation(){
        var images: [UIImage] = []
        images = []
        
        //after animation the letter will be shown
        if toSecure && ccSecure{
            //set animation images in the right order here
            images.append(UIImage(named: "Icon_animated001-007_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-006_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-005_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-004_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-003_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-002_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-001_alpha_verschoben-90.png")!)
        }
            
            //Postcard will be shown after the animation
        else{
            //set animation images here
            images.append(UIImage(named: "Icon_animated001-001_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-002_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-003_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-004_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-005_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-006_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-007_alpha_verschoben-90.png")!)
        }
        
        imageView.animationImages = images
        imageView.animationDuration = 0.75
        imageView.animationRepeatCount = 1
    }
    
    //secure - state after animation
    func setAnimation(secure : Bool){
        var images: [UIImage] = []
        images = []
        
        //after animation the letter will be shown
        if secure{
            //set animation images in the right order here
            images.append(UIImage(named: "Icon_animated001-007_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-006_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-005_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-004_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-003_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-002_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-001_alpha_verschoben-90.png")!)
        }
            
            //Postcard will be shown after the animation
        else{
            //set animation images here
            images.append(UIImage(named: "Icon_animated001-001_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-002_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-003_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-004_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-005_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-006_alpha_verschoben-90.png")!)
            images.append(UIImage(named: "Icon_animated001-007_alpha_verschoben-90.png")!)
        }
        
        imageView.animationImages = images
        imageView.animationDuration = 0.75
        imageView.animationRepeatCount = 1
    }
    
}

