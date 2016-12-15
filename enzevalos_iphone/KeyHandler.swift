//
//  KeyHandler.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 16.11.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation
import KeychainAccess

class KeyHandler {
    private static var handler:KeyHandler? = nil
    
    private var kchain: KeychainWrapper
    private var keychain: Keychain
    
    private init(){
        kchain = KeychainWrapper()
        keychain = Keychain(service: "Enzevalos").accessibility(.WhenUnlocked)
    }
    
    static func createHandler() -> KeyHandler{
        if KeyHandler.handler == nil {
            KeyHandler.handler = KeyHandler.init()
        }
        return KeyHandler.handler!
    }
    
    /*return the latest key added to the handler*/
    func getKeyByAddr(addr: String) -> KeyWrapper? {
        let mail = addr.lowercaseString
        if (try? keychain.getData(mail+"-index")) != nil {//kchain.myObjectForKey(mail+"-index").integerValue{
            if let indexData = (try? keychain.getData(mail+"-index")!){
                var index : Int16 = 0
                indexData.subdataWithRange(NSRange(location: 0,length: 2)).getBytes(&index, length: sizeof(Int16))//range: NSRange(location: 10, length: sizeof(Int16)+10))
                if index >= 1 {
                    if let key = (try? keychain.getData(mail+"-"+String(index)))! {//kchain.myObjectForKey(mail+"-"+String(index)) {
                        return NSKeyedUnarchiver.unarchiveObjectWithData(key) as? KeyWrapper //key! as? KeyWrapper
                    }
                }
            }
        }
        return nil
    }
    
    /* hole Index
     if (try? keychain.getData(mail+"-index")) != nil {//kchain.myObjectForKey(mail+"-index").integerValue{
        if let indexData = (try? keychain.getData(mail+"-index")!){
            var index = 0
            indexData.getBytes(&index, length: sizeof(Int8))
        }
     }
    */
    
    //Only for internal use; DO NOT CALL
    func updateKeyForAddrs(keyWrapper: KeyWrapper, addr: [String]){
        //key.key.primaryKeyPacket.bodyData
//        for mail in key.addresses {
//            if let index = kchain.myObjectForKey(mail+"-index").integerValue{
//                if index >= 1 {
//                    kchain.mySetObject(key, forKey: mail+"-"+String(index))
//                    kchain.writeToKeychain()
//                }
//            }
//        }
    }
    
    func updateKey(keyWrapper: KeyWrapper){
        if let index = kchain.myObjectForKey(keyWrapper.address+"-index").integerValue{
            if index >= 1 {
                if let key = kchain.myObjectForKey(keyWrapper.address+"-"+String(index)) {
                    if (key as! KeyWrapper).key.primaryKeyPacket.bodyData == keyWrapper.key.primaryKeyPacket.bodyData {
                        kchain.mySetObject(keyWrapper, forKey: keyWrapper.address)
                        kchain.writeToKeychain()
                    }
                }
            }
        }
    }
    
    /*only the PGPKey will be used to compare*/
    func getAddrsByKey(key : KeyWrapper) -> [String] {
        let addrs = kchain.myObjectForKey(key.key.primaryKeyPacket.bodyData!) as? [String]
        if addrs != nil {
            return addrs!
        }
        return []
    }
    
    /*for now only the last key added to the handler will be shown*/
    func getKeysByAddr(addr: String) -> [KeyWrapper] {
        var keys : [KeyWrapper?] = []
        //maybe get all keys here in later versions
        keys.append(self.getKeyByAddr(addr))
        
        var finalKeys : [KeyWrapper] = []
        for k in keys {
            if k != nil {
                finalKeys.append(k!)
            }
        }
        
        return finalKeys
    }
    
    
    //TODO add entry with PGPKey as searchKey -done
    func addKey(key: PGPKey) {
        var users : [String]? = []
        for user in key.users {
            if user.userID != nil {
                var mail: String = user.userID!
                if user.userID!.containsString("<") {
                    mail = String(mail.characters.split("<")[1])
                }
                mail = mail.stringByReplacingOccurrencesOfString(">", withString: "")
                mail = mail.lowercaseString
                users!.append(mail)
        
                var index : Int16 = 0
                
                if (try? keychain.getData(mail+"-index")) != nil {
                    if let indexData = (try? keychain.getData(mail+"-index"))!{
                        indexData.getBytes(&index, length: sizeof(Int16))
                    }
                }
                /*if kchain.myObjectForKey(mail+"-index") != nil && kchain.myObjectForKey(mail+"-index").integerValue >= 1{
                    index = kchain.myObjectForKey(mail+"-index").integerValue
                }*/
                index += 1
                keychain[data: mail+"-index"] = NSData(bytes: &index, length: sizeof(Int16))//NSKeyedArchiver.archivedDataWithRootObject(index)
                keychain[data: mail+"-"+String(index)] = NSKeyedArchiver.archivedDataWithRootObject(KeyWrapper(key: key, mailaddress: mail))
                //kchain.mySetObject(index, forKey: mail+"-index")
                //kchain.mySetObject(KeyWrapper(key: key, mailaddress: mail), forKey: mail+"-"+String(index))
                //kchain.writeToKeychain()
            }
        }
        keychain[data: String(key.primaryKeyPacket.bodyData)] = NSKeyedArchiver.archivedDataWithRootObject(users!)
        //kchain.mySetObject(users, forKey: key.primaryKeyPacket.bodyData!)
        //kchain.writeToKeychain()
    }
    
    func addPrivateKey(key: PGPKey) {
        let mail = MailHandler.getAddr().lowercaseString
        
        var index : Int16 = 0
        
        if (try? keychain.getData(mail+"-private-index")) != nil {
            if let indexData = (try? keychain.getData(mail+"-private-index"))!{
                indexData.getBytes(&index, length: sizeof(Int16))
            }
        }
        
        if index < 0 {
            index = 0
        }
        
        index += 1
        keychain[data: mail+"-private-index"] = NSData(bytes: &index, length: sizeof(Int16))
        keychain[data: mail+"-private-"+String(index)] = NSKeyedArchiver.archivedDataWithRootObject(KeyWrapper(key: key, mailaddress: mail))
    }
    
    func getPrivateKey() -> KeyWrapper? {
        let mail = MailHandler.getAddr().lowercaseString
        
        var index : Int16 = 0
        
        if (try? keychain.getData(mail+"-private-index")) != nil {
            if let indexData = (try? keychain.getData(mail+"-private-index"))!{
                indexData.getBytes(&index, length: sizeof(Int16))
            }
        }
        
        if index >= 1 {
            if let key = (try? keychain.getData(mail+"-private-"+String(index))) {
                return NSKeyedUnarchiver.unarchiveObjectWithData(key!) as? KeyWrapper
            }
        }
        return nil
    }
    
    /**
     * remove last privateKey
     */
    func resetPrivateKey(){
        let mail = MailHandler.getAddr().lowercaseString
        
        var index : Int16 = 0
        
        if (try? keychain.getData(mail+"-private-index")) != nil {
            if let indexData = (try? keychain.getData(mail+"-private-index"))!{
                indexData.getBytes(&index, length: sizeof(Int16))
            }
        }
        
        if index > 0 {
            keychain[data: mail+"-private-"+String(index)] = nil
            index -= 1
            keychain[data: mail+"-private-index"] = NSData(bytes: &index, length: sizeof(Int16))
        }
        
    }
    
    func reset(addr: String){
        let mail = addr.lowercaseString
        if (try? keychain.getData(mail+"-index")) != nil {//kchain.myObjectForKey(mail+"-index").integerValue{
            if let indexData = (try? keychain.getData(mail+"-index")!){
                var index : Int16 = 0
                indexData.getBytes(&index, length: sizeof(Int16))
                index = 0
                keychain[data: mail+"-index"] = NSData(bytes: &index, length: sizeof(Int16))
            }
        }
    }
    
    //TODO convert to use of keychain instead of kchain
    func addKeyForMailaddress(address: String, keyWrapper: KeyWrapper) {
        let mail = address.lowercaseString
        var index = 0
        if kchain.myObjectForKey(mail+"-index") != nil && kchain.myObjectForKey(mail+"-index").integerValue >= 1{
            index = kchain.myObjectForKey(mail+"-index").integerValue
        }
        index += 1
        
        var addrsByKey : [String]? = []
        addrsByKey = kchain.myObjectForKey(keyWrapper.key.primaryKeyPacket.bodyData!) as? [String]
        if addrsByKey == nil {
            addrsByKey = Optional([mail])
        }
        
        
        kchain.mySetObject(index, forKey: mail+"-index")
        kchain.mySetObject(keyWrapper, forKey: mail+"-"+String(index))
        kchain.mySetObject(addrsByKey, forKey: keyWrapper.key.primaryKeyPacket.bodyData!)
        kchain.writeToKeychain()
    }
    
    func addrHasKey(address: String) -> Bool {
        let mail = address.lowercaseString
        if (try? keychain.getData(mail+"-index")) != nil {
            if let indexData = (try? keychain.getData(mail+"-index")){
                if indexData == nil {
                    return false
                }
                var index = 0
                indexData!.getBytes(&index, length: sizeof(Int8))
                return index >= 1
            }
        }
        /*if kchain.myObjectForKey(mail+"-index") != nil{
            if kchain.myObjectForKey(mail+"-index").integerValue >= 1 {
                return true
            }
        }*/
        return false
    }
}
