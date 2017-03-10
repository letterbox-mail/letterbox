//
//  VENDataDelegate.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 29.07.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import VENTokenField

class VENDataDelegate : NSObject, VENTokenFieldDataSource , VENTokenFieldDelegate {
    
    var changeFunc: (VENTokenField -> Void) = {(_ : VENTokenField) -> Void in
        //print ("hallo")
    }
    
    var beginFunc: (VENTokenField -> Void) = {(_ : VENTokenField) -> Void in }
    
    var tappedWhenSelectedFunc: (String -> Void)? = nil
    
    //Used later to show enzevalos-Contacts
    //Have a look at tokenField(... didTappedTokenTwice ...)
    //var doubleTapFunc
    
    override init() {
        super.init()
    }
    
    init(changeFunc: (VENTokenField -> Void), tappedWhenSelectedFunc: (String -> Void)?/*, beginFunc: (VENTokenField -> Void)*/){
        self.changeFunc = changeFunc
        self.tappedWhenSelectedFunc = tappedWhenSelectedFunc
        //self.beginFunc = beginFunc
        super.init()
    }
    
    func tokenField(tokenField: VENTokenField, didChangeText text: String?) {
        changeFunc(tokenField)
    }
   
    func tokenField(tokenField: VENTokenField, colorSchemeForTokenAtIndex index: UInt) -> UIColor {
        if EnzevalosEncryptionHandler.hasKey(tokenField.mailTokens[Int(index)] as! String) {
            return UIColor.init(red: 0, green: 122.0/255.0, blue: 1, alpha: 1)
        }
        return UIColor.orangeColor()
    }
    
    func tokenFieldDidBeginEditing(tokenField: VENTokenField) {
        //print("begin")
        //print(numberOfTokensInTokenField(tokenField))
        beginFunc(tokenField)
    }
    
    func tokenField(tokenField: VENTokenField, didEnterText text: String) {
        tokenField.textTokens.addObject(text.lowercaseString)
        if AddressHandler.inContacts(text) {
            //TODO Mailadresse aus Kontakt holen
        }
        else {
            tokenField.mailTokens.addObject(text)
        }
        tokenField.reloadData()
        changeFunc(tokenField)
        tokenField.sendActionsForControlEvents(UIControlEvents.EditingDidEnd)
    }
    
    func tokenField(tokenField: VENTokenField, didEnterText text: String, mail email: String) {
        tokenField.textTokens.addObject(text)
        tokenField.mailTokens.addObject(email)
        tokenField.reloadData()
        changeFunc(tokenField)
        tokenField.sendActionsForControlEvents(UIControlEvents.EditingDidEnd)
    }
    
    func tokenField(tokenField: VENTokenField, didDeleteTokenAtIndex index: UInt) {
        if LogHandler.logging {
            LogHandler.doLog(UIViewResolver.resolve(tokenField.tag), interaction: "delete", point: CGPoint(x: Int(index), y: 0), comment: (tokenField.textTokens[Int(index)] as! String)+" "+(tokenField.mailTokens[Int(index)] as! String))
        }
        tokenField.textTokens.removeObjectAtIndex(Int(index))
        tokenField.mailTokens.removeObjectAtIndex(Int(index))
        tokenField.reloadData()
        tokenField.sendActionsForControlEvents(UIControlEvents.EditingDidEnd)
    }
    
    func tokenField(tokenField: VENTokenField, titleForTokenAtIndex index: UInt) -> String {
        return tokenField.textTokens[Int(index)] as! String
    }
    
    func numberOfTokensInTokenField(tokenField: VENTokenField) -> UInt {
        return UInt((tokenField.textTokens.count))
    }
    
    func tokenFieldCollapsedText(tokenField: VENTokenField) -> String {
        var text : String = "names: "
        text.appendContentsOf(String(tokenField.dataSource?.numberOfTokensInTokenField!(tokenField)))
        return text
    }
    
    func tokenField(tokenField: VENTokenField, didChangeContentHeight height: CGFloat) {
        //print("height: ",height)
        for c in tokenField.constraints {
            if (c.identifier == "tokenFieldHeight"){
                c.constant = height
                //print("set height")
            }
        }
    }
    
    //eigene Methoden
    
    func tokenFieldDidEndEditing(tokenF: VENTokenField){
        //print("end")
        if let last = tokenF.inputText() {
            if last.stringByReplacingOccurrencesOfString(" ", withString: "") != "" {
                tokenField(tokenF, didEnterText: last)
            }
        }
    }
    
    /*func tokenStrings(tokenField: VENTokenField) -> [String]{
        return tokenField.textTokens
    }*/
    
    func isSecure(tokenField: VENTokenField) -> Bool {
        var secure = true
        for entry in tokenField.mailTokens{
            secure = secure && EnzevalosEncryptionHandler.hasKey(DataHandler.handler.getContactByAddress(entry as! String))
        }
        return secure
    }
    
    func tokenField(tokenField: VENTokenField, didTappedTokenTwice index: UInt){
        if let fun = tappedWhenSelectedFunc {
            fun(tokenField.mailTokens[Int(index)] as! String)
        }
    }
}
