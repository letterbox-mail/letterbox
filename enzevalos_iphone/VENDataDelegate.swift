//
//  VENDataDelegate.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 29.07.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import VENTokenField

class VENDataDelegate : NSObject, VENTokenFieldDataSource , VENTokenFieldDelegate {
    
    var changeFunc: ((VENTokenField) -> Void) = {(_ : VENTokenField) -> Void in
        //print ("hallo")
    }
    
    var beginFunc: ((VENTokenField) -> Void) = {(_ : VENTokenField) -> Void in }
    
    var deleteFunc: (() -> Void) = {() -> Void in }
    
    var tappedWhenSelectedFunc: ((String) -> Void)? = nil
    
    //Used to show enzevalos-Contacts
    //Have a look at tokenField(... didTappedTokenTwice ...)
    //var doubleTapFunc
    
    override init() {
        super.init()
    }
    
    init(changeFunc: @escaping ((VENTokenField) -> Void), tappedWhenSelectedFunc: ((String) -> Void)?/*, beginFunc: (VENTokenField -> Void)*/, deleteFunc: @escaping (() -> Void)){
        self.changeFunc = changeFunc
        self.tappedWhenSelectedFunc = tappedWhenSelectedFunc
        self.deleteFunc = deleteFunc
        //self.beginFunc = beginFunc
        super.init()
    }
    
    func tokenField(_ tokenField: VENTokenField, didChangeText text: String?) {
        changeFunc(tokenField)
    }
   
    func tokenField(_ tokenField: VENTokenField, colorSchemeForTokenAt index: UInt) -> UIColor {
        if EnzevalosEncryptionHandler.hasKey(tokenField.mailTokens[Int(index)] as! String) {
            return UIColor.init(red: 0, green: 122.0/255.0, blue: 1, alpha: 1)
        }
        return UIColor.orange
    }
    
    func tokenFieldDidBeginEditing(_ tokenField: VENTokenField) {
        //print("begin")
        //print(numberOfTokensInTokenField(tokenField))
        beginFunc(tokenField)
    }
    
    func tokenField(_ tokenField: VENTokenField, didEnterText text: String) {
        tokenField.textTokens.add(text.lowercased())
        if AddressHandler.inContacts(text) {
            //TODO Mailadresse aus Kontakt holen
        }
        else {
            tokenField.mailTokens.add(text)
        }
        tokenField.reloadData()
        changeFunc(tokenField)
        tokenField.sendActions(for: UIControlEvents.editingDidEnd)
    }
    
    func tokenField(_ tokenField: VENTokenField, didEnterText text: String, mail email: String) {
        tokenField.textTokens.add(text)
        tokenField.mailTokens.add(email)
        tokenField.reloadData()
        changeFunc(tokenField)
        tokenField.sendActions(for: UIControlEvents.editingDidEnd)
    }
    
    func tokenField(_ tokenField: VENTokenField, didDeleteTokenAt index: UInt) {
        if LogHandler.logging {
            LogHandler.doLog(UIViewResolver.resolve(tokenField.tag), interaction: "delete", point: CGPoint(x: Int(index), y: 0), comment: (tokenField.textTokens[Int(index)] as! String)+" "+(tokenField.mailTokens[Int(index)] as! String))
        }
        tokenField.textTokens.removeObject(at: Int(index))
        tokenField.mailTokens.removeObject(at: Int(index))
        tokenField.reloadData()
        deleteFunc()
        tokenField.sendActions(for: UIControlEvents.editingDidEnd)
    }
    
    func tokenField(_ tokenField: VENTokenField, titleForTokenAt index: UInt) -> String {
        return tokenField.textTokens[Int(index)] as! String
    }
    
    func numberOfTokensInTokenField(tokenField: VENTokenField) -> UInt {
        return UInt((tokenField.textTokens.count))
    }
    
    func tokenFieldCollapsedText(_ tokenField: VENTokenField) -> String {
        var text : String = "names: "
        text.appendContentsOf(String(tokenField.dataSource?.numberOfTokensInTokenField!(tokenField)))
        return text
    }
    
    func tokenField(_ tokenField: VENTokenField, didChangeContentHeight height: CGFloat) {
        //print("height: ",height)
        for c in tokenField.constraints {
            if (c.identifier == "tokenFieldHeight"){
                c.constant = height
                //print("set height")
            }
        }
    }
    
    //eigene Methoden
    
    func tokenFieldDidEndEditing(_ tokenF: VENTokenField){
        //print("end")
        if let last = tokenF.inputText() {
            if last.replacingOccurrences(of: " ", with: "") != "" {
                tokenField(tokenF, didEnterText: last)
            }
        }
    }
    
    /*func tokenStrings(tokenField: VENTokenField) -> [String]{
        return tokenField.textTokens
    }*/
    
    func isSecure(_ tokenField: VENTokenField) -> Bool {
        var secure = true
        for entry in tokenField.mailTokens{
            secure = secure && EnzevalosEncryptionHandler.hasKey(entry as! String) //KeyHandler.getHandler().addrHasKey(entry as! String)//AddressHandler.proveAddress(entry as! NSString)
        }
        return secure
    }
    
    func tokenField(_ tokenField: VENTokenField, didTappedTokenTwice index: UInt){
        if let fun = tappedWhenSelectedFunc {
            fun(tokenField.mailTokens[Int(index)] as! String)
        }
    }
}
