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

class VCSend04: UIViewController, UITextViewDelegate{
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        dataDelegate = VENDataDelegate(changeFunc: self.editName)
        tableDataDelegate = TableViewDataDelegate(insertCallback: self.insertName)
        collectionDataDelegate = CollectionDataDelegate(suggestionFunc: AddressHandler.frequentAddresses, insertCallback: self.insertName)
        imageView.contentMode = .ScaleAspectFit
        imageView.image = UIImage(named: "Icon_animated001-001_alpha_verschoben-90.png")!
        setAnimation(false)
        self.navigationItem.titleView = imageView
        
        textView.delegate = self
        
        subjectText.toLabelText = "Subject: "
        
        toText.delegate = dataDelegate
        toText.dataSource = dataDelegate
        toText.inputTextFieldKeyboardType = UIKeyboardType.EmailAddress
        toCollectionview.delegate = collectionDataDelegate
        toCollectionview.dataSource = collectionDataDelegate
        toCollectionview.registerNib(UINib(nibName: "FrequentCell", bundle: nil), forCellWithReuseIdentifier: "frequent")
        toCollectionviewHeight.constant = 0
        ccText.delegate = dataDelegate
        ccText.dataSource = dataDelegate
        ccText.toLabelText = "Cc:"
        ccCollectionview.delegate = collectionDataDelegate
        ccCollectionview.dataSource = collectionDataDelegate
        ccCollectionview.registerNib(UINib(nibName: "FrequentCell", bundle: nil), forCellWithReuseIdentifier: "frequent")
        ccCollectionviewHeight.constant = 0
        
        //will always be thrown, when a token was editied
        toText.addTarget(self, action: #selector(self.newInput(_:)), forControlEvents: UIControlEvents.EditingDidEnd)
        ccText.addTarget(self, action: #selector(self.newInput(_:)), forControlEvents: UIControlEvents.EditingDidEnd)
        
        toText.delegate?.tokenField!(toText, didEnterText: "jakob.bode@fu-berlin.de")
        
        seperator1Height.constant = 0.5
        seperator2Height.constant = 0.5
        seperator3Height.constant = 0.5
        
        //ccText.horizontalInset = 9
    
        ccText.inputTextFieldKeyboardType = UIKeyboardType.EmailAddress
        scrollview.clipsToBounds = true
        
        tableview.delegate = tableDataDelegate
        tableview.dataSource = tableDataDelegate
        tableview.registerNib(UINib(nibName: "ContactCell", bundle: nil), forCellReuseIdentifier: "contacts")
        
        //tableview.registerClass(ContactCell.self, forCellReuseIdentifier: "contacts")
        
        let indexPath = NSIndexPath()
        //tableview.registerNib(UINib(nibName: "nib", bundle: nil), forCellReuseIdentifier: "contacts")
        
        //tableview.cellForRowAtIndexPath(indexPath)?.textLabel?.text = "hallo2"
        tableview.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        
        //register KeyBoardevents
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardOpen(_:)), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardClose(_:)), name:UIKeyboardWillHideNotification, object: nil);
        
        //        UIView.animateWithDuration(0.5, delay: 1, options: UIViewAnimationOptions() ,animations: {
        //            self.button!.setImage(self.imageView.image!, forState: UIControlState.Normal)
        //            //self.button!.frame = CGRectOffset(self.button!.frame, 0, 100)
        //            }, completion: nil)
        //showMessage("hallihallo")
        
        //doContact()
    }
    
    override func viewDidAppear(animated: Bool){
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func editName(tokenField : VENTokenField){
        if let inText = tokenField.inputText(){
            if inText != "" {
                scrollview.scrollEnabled = false
                //ccCollectionviewHeight.constant = 0
                //toCollectionviewHeight.constant = 0
                scrollview.contentOffset = CGPoint(x: 0, y: tokenField.frame.origin.y-self.topLayoutGuide.length)
                print(tokenField.frame.origin.y, " ", tokenField.frame.maxY)
                tableviewBegin.constant = tokenField.frame.maxY-tokenField.frame.origin.y
                tableviewHeight.constant = keyboardY - tableviewBegin.constant - (self.navigationController?.navigationBar.frame.maxY)!
                //tableDataDelegate.tokenField = tokenField
                searchContacts(inText)
                //tableview.frame.origin = CGPoint(x:0, y:tokenField.frame.origin.y+tokenField.frame.maxY)
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
        }
        else if ccText.isFirstResponder(){
            ccText.delegate?.tokenField!(ccText, didEnterText: name, mail: address)
        }
        //collectionDataDelegate.alreadyInserted = (toText.mailTokens as NSArray as! [String])+(ccText.mailTokens as NSArray as! [String])
    }
    
    func searchContacts(prefix: String){
        AppDelegate.getAppDelegate().requestForAccess({access in
            print(access)
        })
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        if authorizationStatus == CNAuthorizationStatus.Authorized {
            do {
                let contacts = try AppDelegate.getAppDelegate().contactStore.unifiedContactsMatchingPredicate(CNContact.predicateForContactsMatchingName(prefix), keysToFetch: [CNContactFormatter.descriptorForRequiredKeysForStyle(CNContactFormatterStyle.FullName), CNContactEmailAddressesKey, CNContactImageDataKey, CNContactThumbnailImageDataKey])
//                print(contacts)
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
            print("contacts done")
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
            var info = notification.userInfo!
            let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            reducedSize = keyboardFrame.size.height
        
            keyboardY = keyboardFrame.origin.y
            print("keyboard ", keyboardY)
        
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
                //self.bottomConstraint.constant = keyboardFrame.size.height + 20 //gaaaaaanz alt
                
                //self.textViewHeight.constant -= self.reducedSize
                //self.scrollview.heightAnchor -= self.reducedSize
                
                //self.bottomConstraint.constant = self.reducedSize
                let contentInsets = UIEdgeInsetsMake(/*(self.navigationController?.navigationBar.frame.height)!+*/self.topLayoutGuide.length/*self.navigationController!.navigationBar.frame.size.height*//*0.0*/, 0.0, self.reducedSize, 0.0)
                self.scrollview!.contentInset = contentInsets
                //self.scrollview!.setContentOffset(CGPoint(x: self.scrollview!.contentOffset.x,y: self.scrollview!.contentOffset.y-self.reducedSize), animated: false)
                //self.scrollview!.scrollIndicatorInsets = contentInsets
            })
            //print(self.bottomConstraint.constant)
        //}
    }
    
    func keyboardClose(notification: NSNotification) {
        if reducedSize != 0{
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                //self.bottomConstraint.constant = keyboardFrame.size.height + 20 //auch ganz alt
                //self.textViewHeight.constant += self.reducedSize
                //self.scrollview.heightAnchor -= self.reducedSize
                
                //self.bottomConstraint.constant = 0
                self.reducedSize = 0
                let contentInsets = UIEdgeInsetsMake(self.topLayoutGuide.length/*0.0*/, 0.0, self.reducedSize, 0.0)
                self.scrollview!.contentInset = contentInsets
                //self.scrollview!.scrollIndicatorInsets = contentInsets
            })
            if !toText.isFirstResponder() {
                toCollectionviewHeight.constant = 0
            }
            if !ccText.isFirstResponder() {
                ccCollectionviewHeight.constant = 0
            }
        }
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
                    }, completion: nil)
                UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.CurveEaseIn ,animations: {
                    self.navigationController?.navigationBar.barTintColor = UIColor.groupTableViewBackgroundColor()
                    }, completion: nil)
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

