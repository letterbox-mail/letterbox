
//
//  Autocrypt.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 27.10.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import Foundation

// See: https://autocrypt.org/level1.html

class Autocrypt {
    static let ENFORCEENCRYPTION = true
    static let AUTOCRYPTHEADER = "Autocrypt"
    static let SETUPMESSAGE = "Autocrypt-Setup-Message"
    static let ADDR = "addr"
    static let TYPE = "type"
    static let ENCRYPTION = "prefer-encrypt"
    static let KEY = "keydata"
    static let EXTRAHEADERS = [Autocrypt.AUTOCRYPTHEADER, Autocrypt.SETUPMESSAGE]
    
    
    var addr: String = ""
    var type: CryptoScheme = .PGP
    var prefer_encryption: EncState = EncState.NOAUTOCRYPT
    var key: String = ""
    
    init(addr: String, type: String, prefer_encryption: String, key: String) {
        self.addr = addr
        self.key = key
        setPrefer_encryption(prefer_encryption)
    }
    
    
    convenience init(header: MCOMessageHeader) {
        var autocrypt = header.extraHeaderValue(forName: Autocrypt.AUTOCRYPTHEADER)
        var field: [String]
        var addr = ""
        var type = "1"
        var pref = "mutual"
        var key = ""
        
        if autocrypt != nil {
            autocrypt = autocrypt?.trimmingCharacters(in: .whitespacesAndNewlines)
            let autocrypt_fields = autocrypt?.components(separatedBy: ";")
            for f in autocrypt_fields! {
                field = f.components(separatedBy: "=")
                if field.count > 1 {
                    let flag = field[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    var value = field[1]
                    if field.count > 2 {
                        for i in 2...(field.count - 1) {
                            value = value + "="
                            value = value + field[i]
                        }
                    }
                    switch flag {
                    case Autocrypt.ADDR:
                        addr = value.trimmingCharacters(in: .whitespacesAndNewlines)
                        addr = addr.lowercased()
                        break
                    case Autocrypt.TYPE:
                        type = value.trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    case Autocrypt.ENCRYPTION:
                        pref = value.trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    case Autocrypt.KEY:
                        if value.count > 0 {
                            key = value
                        }
                        break
                    default:
                        break
                    }
                }
            }
        }
        self.init(addr: addr, type: type, prefer_encryption: pref, key: key)
    }
    
    
    func setPrefer_encryption(_ input: String){
        let pref = input.lowercased()
        if pref == "yes" || pref == "mutual" {
            self.prefer_encryption = EncState.MUTUAL
        } else if pref == "no" {
            self.prefer_encryption = EncState.NOPREFERENCE
        }
        else {
            self.prefer_encryption = EncState.NOPREFERENCE
        }
    }
    
    func toString() -> String {
        return "Addr: \(addr) | type: \(type) | encryption? \(prefer_encryption) key size: \(key.count)"
    }
    
    static func addAutocryptHeader(_ builder: MCOMessageBuilder) {
        let adr = (UserManager.loadUserValue(Attribute.userAddr) as! String).lowercased()
        let skID = DataHandler.handler.prefSecretKey().keyID
        
        let pgp = SwiftPGP()
        if let id = skID {
            let enc = "yes"
            if let key = pgp.exportKey(id: id, isSecretkey: false, autocrypt: true) {
                var string = "\(ADDR)=" + adr
                if enc == "yes" {
                    string = string + "; \(ENCRYPTION)=mutual"
                }
                string = string + "; \(KEY)= \n" + key
                builder.header.setExtraHeaderValue(string, forName: AUTOCRYPTHEADER)
            }
        }
    }
    
    static func recommandateEncryption (receiver: MailAddress) -> (hasAutocrypt: Bool, recommandEnc: Bool){
        if receiver.hasKey, let key = receiver.primaryKey {
            if key.prefer_encryption == .NOAUTOCRYPT {
                return (false, ENFORCEENCRYPTION)
            }
            else if key.prefer_encryption == .MUTUAL {
                return (true, true)
            }
            return (true, false)
        }
        else {
            return (false, false)
        }
    }
    
    static func createAutocryptKeyExport(builder: MCOMessageBuilder, keyID: String, key: String) {
        builder.header.setExtraHeaderValue("v1", forName: SETUPMESSAGE)
        
        builder.addAttachment(MCOAttachment.init(text: "This message contains a secret for reading secure mails on other devices. \n 1) Input the passcode from your smartphone to unlock the message on your other device. \n 2) Import the secret key into your pgp program on the device.  \n\n For more information visit: https://userpage.fu-berlin.de/letterbox/faq.html#otherDevices \n\n"))
        
        // See: https://autocrypt.org/level1.html#autocrypt-setup-message
        let filename = keyID+".asc.asc"
        if let keyAttachment = MCOAttachment.init(contentsOfFile: filename){
            keyAttachment.mimeType = "application/autocrypt-setup"
            keyAttachment.setContentTypeParameterValue("UTF-8", forName: "charset")
            keyAttachment.setContentTypeParameterValue(filename, forName: "name")
            keyAttachment.filename = filename
            keyAttachment.data = key.data(using: .utf8)
            
            builder.addAttachment(keyAttachment)
            
        }
        if let keyAttachment = MCOAttachment.init(text: key){
            builder.addAttachment(keyAttachment)
        }
    }
    
}
