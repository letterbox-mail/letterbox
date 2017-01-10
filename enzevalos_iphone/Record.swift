//
//  Record.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 06/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Contacts
import UIKit


public protocol Record: Comparable {
    var name: String{get}
    var isSecure: Bool{get}
    var isVerified: Bool {get}
    func getContact()-> EnzevalosContact
    func getFromMails()->[Mail]
    func updateMails(mail:Mail)->Bool
    func getCNContact()-> CNContact?
    func getColor()-> UIColor
    func getImageOrDefault()-> UIImage
    
}

extension Record {
    
    func hasKey() -> Bool {
        // TODO FIX ME
        // let handler = KeyHandler.getHandler()
        //for mail in self.emailAddresses {
          //  if handler.addrHasKey(mail.value as! String) {
            //    return true
            //}
        //}
        return false
    }
    
    //TODO check expiration date
    //TODO add ability to choose different keys
    func getKey() -> KeyWrapper? {
        //let handler = KeyHandler.getHandler()
      //  for mail in self.emailAddresses {
        //    if handler.addrHasKey(mail.value as! String) {
          //      return handler.getKeyByAddr(mail.value as! String)
            //}
        //}
        return nil
    }
    
    func getKey(mailaddress: String) -> KeyWrapper? {
        let mail = mailaddress.lowercaseString
        let handler = KeyHandler.getHandler()
        return handler.getKeyByAddr(mail)
    }
    
    //TODO fertigmachen
    func addKey(key: PGPKey, mailaddress: String){
        //let handler = KeyHandler.getHandler()
        //handler.addKeyForMailaddress(mailaddress, key: key)
    }
    
    func addPGPKey(key: KeyWrapper, mailaddress: String){
        let handler = KeyHandler.getHandler()
        handler.addKeyForMailaddress(mailaddress, keyWrapper: key)
    }
}

