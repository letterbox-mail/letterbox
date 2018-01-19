//
//  SwiftPGP.swift
//  ObjectivePGP
//
//  Created by Oliver Wiese on 25.09.17.
//  Copyright © 2017 Marcin Krzyżanowski. All rights reserved.
//

import Foundation
import Security
import KeychainAccess

class SwiftPGP: Encryption{

    let cryptoScheme = CryptoScheme.PGP
    
    let PasscodeSize = 36
    
    
    private func generatePW(size: Int) -> String{
        let file = open("/dev/urandom", O_RDONLY)
        if file >= 0{
            var pw = ""
            while pw.count < size{
                var bits: UInt64 = 0
                read(file, &bits, MemoryLayout<UInt64>.size)
                
                
            }
             return generatePW(arc4: size)
        }
        else{
            return generatePW(arc4: size)
        }
    }
    
    private func generatePW(arc4 size: Int)-> String{
        var pw = ""
        for i in 0..<size{
            // digit from 0...9
            let p = Int(arc4random_uniform(10))
            pw.append(String(p))
            if i % 4 == 3 && i < size - 4{
                pw.append("-")
            }
        }
        return pw
    }
    
    private var keychain: Keychain{
        get{
            return Keychain(service: "Enzevalos/PGP")
        }
        
    }
    
    private var pwKeyChain: Keychain{
        get{
            return Keychain(service: "Enzevalos/PGP/Password")
        }
    }
    
    private var exportPwKeyChain: Keychain{
        get{
            return Keychain(service: "Enzevalos/PGP/ExportPassword")
        }
    }
    
    private func storeKey(key: Key) -> String{
        let keyring = Keyring()
        keyring.import(keys: [key])
        let id = key.keyID.longIdentifier
        if let testData = try? keychain.getData(id), testData != nil{
            // merge keys. i.e. secret key stored and key is public key.
            if let keys = try? ObjectivePGP.readKeys(from: testData!){
                keyring.import(keys: keys)
            }
        }
        if let k = keyring.findKey(id){
            if let data = try? k.export(){
                keychain[data: id] = data
            }
        }
        return id
    }
    
    func loadKey(id: String) -> Key?{
        do{
            if let data = try keychain.getData(id){
                if let keys = try? ObjectivePGP.readKeys(from: data), keys.count > 0{
                    if let key = keys.first{
                        return key
                    }
                }
            }
        } catch{
            return nil
        }
        return nil
    }
    
    func loadExportPasscode(id: String) -> String?{
        do{
            if let pw = try exportPwKeyChain.getString(id){
                return pw
            }
        } catch{
            return nil
        }
        return nil
    }
    
    private func loadPassword(id: String) -> String?{
        do{
            if let pw = try pwKeyChain.getString(id){
                return pw
            }
        } catch{
            return nil
        }
        return nil
    }
    
    private func loadPassword(key: Key?) -> String?{
        if let k = key{
            return loadPassword(id: k.keyID.longIdentifier)
        }
        return nil
    }
    
    func generateKey(adr: String) -> String{
        let gen = KeyGenerator()
        let pw: String? = nil //generatePW(size: PasscodeSize)
        let key = gen.generate(for: "\(adr) <\(adr)>", passphrase: pw)
        if pw != nil{
            pwKeyChain[key.keyID.longIdentifier] = pw
        }
        return storeKey(key: key)
    }
    
    func importKeys (key: String,  pw: String?, isSecretKey: Bool, autocrypt: Bool) throws -> [String]{
        var keys = [Key]()
        if autocrypt{
            let keyData = ObjectivePGP.transformKey(key)
            if let readKeys = try? ObjectivePGP.readKeys(from: keyData){
                keys.append(contentsOf: readKeys)
            }
        }
        else{
            if let data = key.data(using: .utf8){
                if let readKeys = try? ObjectivePGP.readKeys(from: data){
                    keys.append(contentsOf: readKeys)
                }
            }
        }
        for key in keys{
            if key.isSecret{
                //test key{
                try ObjectivePGP.sign("1234".data(using: .utf8)!, detached: false, using: [key], passphraseForKey: {(key) -> String? in return pw})
            }
        }
        return storeMultipleKeys(keys: keys, pw: pw, secret: isSecretKey)
    }
    
    func importKeys(data: Data,  pw: String?, secret: Bool) throws -> [String]{
        if let keys = try? ObjectivePGP.readKeys(from: data){
            return storeMultipleKeys(keys: keys, pw: pw, secret: secret)
        }
        return [String]()
    }

    
    func importKeysFromFile(file: String,  pw: String?) throws -> [String]{
        if let keys = try? ObjectivePGP.readKeys(fromPath: file){
            return storeMultipleKeys(keys: keys, pw: pw, secret: false)
        }
        return [String]()
    }
    
    private func storeMultipleKeys(keys: [Key], pw: String?, secret: Bool )-> [String]{
        var ids = [String]()
        for k in keys{
            if k.isSecret && secret || !k.isSecret && !secret{
                ids.append(storeKey(key: k))
                if let password = pw{
                    pwKeyChain[k.keyID.longIdentifier] = password
                }
            }
        }
        return ids
    }
    
    func exportKey(id: String, isSecretkey isSecretKey: Bool, autocrypt: Bool) -> String?{
        if let key = exportKeyData(id: id, isSecretkey: isSecretKey, autocrypt: autocrypt){
            if !isSecretKey && autocrypt{
                return key.base64EncodedString()
            }
            else{
                return String.init(data: key, encoding: .utf8)
            }
        }
        return nil
    }
    
    func exportKeyData(id: String, isSecretkey: Bool, autocrypt: Bool) -> Data?{
        let keyring = Keyring()
        if var key = loadKey(id: id){
            if isSecretkey && key.isSecret{
                keyring.import(keys: [key])
                if let keyData =  keyring.export(key: key, armored: true){
                    if autocrypt{
                        // Create Autocrypt Setup-message
                        // See: https://autocrypt.readthedocs.io/en/latest/level1.html#autocrypt-setup-message
                        var passcode = loadPassword(id: id)
                        if passcode == nil{
                            passcode = generatePW(size: PasscodeSize)
                        }
                        exportPwKeyChain[key.keyID.longIdentifier] = passcode
                        let cipher = try! ObjectivePGP.symmetricEncrypt(keyData, signWith: nil, encryptionKey: passcode, passphrase: passcode, armored: true)
                        
                        return cipher
                    }
                    return keyData
                }
            }            
            if key.isSecret && !isSecretkey{
                var pk: Data
                do{
                    pk = try key.export(keyType: PGPKeyType.public)
                    if let keys = try? ObjectivePGP.readKeys(from: pk), keys.count > 0{
                        key = keys.first!
                        keyring.import(keys: [key])
                    }
                } catch {
                    return nil
                }
            }
            if autocrypt{
                return keyring.export(key: key, armored: false)
            }
            else{
               return keyring.export(key: key, armored: true)
            }
        }
        return nil
    }

    
    func encrypt(plaintext: String, ids: [String], myId: String) -> CryptoObject{
        let keyring = Keyring()
        let signKey = loadKey(id: myId)
        if signKey != nil{
            print("signing id: \(myId)")
            keyring.import(keys: [signKey!])
        }
        let signedAdr = vaildAddress(key: signKey)
        for id in ids{
            if let key = loadKey(id: id){
                keyring.import(keys: [key])
                print("ID to encrypt: \(id)")
            }
        }
        if let data = plaintext.data(using: String.Encoding.utf8){
            do{
                for key in keyring.keys{
                    print("Key: \(key.keyID.longIdentifier) is secret?: \(key.isSecret)")
                }
                let chipher = try ObjectivePGP.encrypt(data, addSignature: true, using: keyring.keys, passphraseForKey: loadPassword)
                let armorChipherString = Armor.armored(chipher, as: .message)
                let armorChipherData = armorChipherString.data(using: .utf8)
                return CryptoObject(chiphertext: armorChipherData, plaintext: plaintext, decryptedData: data, sigState: SignatureState.ValidSignature, encState: EncryptionState.ValidedEncryptedWithCurrentKey, signKey: myId, encType: CryptoScheme.PGP, signedAdrs: signedAdr)
            } catch {
                print("Encryption error!")
                print(error)
            }
        }
        
        
        return CryptoObject(chiphertext: nil, plaintext: nil,decryptedData: nil, sigState: SignatureState.InvalidSignature, encState: EncryptionState.UnableToDecrypt, signKey: nil, encType: cryptoScheme, signedAdrs: signedAdr)
        
    }
    
    func decrypt(data: Data,decryptionIDs: [String], verifyIds: [String], fromAdr: String?) -> CryptoObject{
        var plaindata: Data? = nil
        var plaintext: String? = nil
        var sigState = SignatureState.NoSignature
        var encState = EncryptionState.UnableToDecrypt
        var sigKeyID: String? = nil
        var signedAdr = [String]()
        let prefID = DataHandler.handler.prefSecretKey().keyID
        let keyring = Keyring()
        /*
             DECRYPTION
         */
        // TODO: Maybe consider: try ObjectivePGP.recipientsKeyID(forMessage: ...) but currently not working...
        for decID in decryptionIDs{
            if let decKey = loadKey(id: decID){
                if decID == prefID{
                    let (currentPlain, currentEncState) = decryptMessage(data: data, keys: [decKey], encForCurrentSK: true)
                    if encState != EncryptionState.ValidEncryptedWithOldKey || currentEncState == EncryptionState.ValidedEncryptedWithCurrentKey{
                        plaindata = currentPlain
                        encState = currentEncState
                    }
                }
                keyring.import(keys: [decKey])
            }
        }
        if encState != EncryptionState.ValidedEncryptedWithCurrentKey{
            (plaindata, encState) = decryptMessage(data: data, keys: keyring.keys, encForCurrentSK: false)
        }
        /*
             VERIFICATION
         */
       // test if message ist signed
        sigState = verifyMessage(data: data, keys: keyring.keys)
        
        for id in verifyIds{
            if let key = loadKey(id: id){
                keyring.import(keys: [key])
                let currentState = verifyMessage(data: data, keys: keyring.keys)
                if currentState == SignatureState.ValidSignature{
                    sigState = currentState
                    sigKeyID = id
                    signedAdr = vaildAddress(key: key)
                    break
                }
                if currentState == SignatureState.InvalidSignature{
                    sigState = currentState
                }
            }
        }
        
        if encState == EncryptionState.UnableToDecrypt{
            sigState = SignatureState.NoSignature
        }
        if plaindata != nil{
            plaintext = plaindata?.base64EncodedString()
        }
        return CryptoObject(chiphertext: data, plaintext: plaintext, decryptedData: plaindata, sigState: sigState, encState: encState, signKey: sigKeyID, encType: CryptoScheme.PGP, signedAdrs: signedAdr)
    }
    
    
    func decrypt(data: Data,decryptionId: String?, verifyIds: [String], fromAdr: String?) -> CryptoObject{
        if let decId = decryptionId{
            return decrypt(data: data, decryptionIDs: [decId], verifyIds: verifyIds, fromAdr: fromAdr)
        }
        return decrypt(data: data, decryptionIDs: [String](), verifyIds: verifyIds, fromAdr: fromAdr)
    }
    
    
    private func decryptMessage(data: Data, keys: [Key], encForCurrentSK: Bool) -> (Data?, EncryptionState){
        if let dataString = String(data: data, encoding: .utf8), let unarmored = try? Armor.readArmored(dataString){
            if let plain = try? ObjectivePGP.decrypt(unarmored, andVerifySignature: true, using: keys, passphraseForKey: loadPassword){
                if encForCurrentSK{
                    return (plain, EncryptionState.ValidedEncryptedWithCurrentKey)
                }
                else{
                    return(plain, EncryptionState.ValidEncryptedWithOldKey)
                }
            }
            else{
                return (nil, EncryptionState.UnableToDecrypt)
            }
        }
        return (nil, EncryptionState.NoEncryption)
    }
    
    private func verifyMessage(data: Data, keys: [Key]) -> SignatureState{
        if let dataString = String(data: data, encoding: .utf8), let unarmored = try? Armor.readArmored(dataString){
            do{
                try ObjectivePGP.verify(unarmored, withSignature: nil, using: keys, passphraseForKey: loadPassword)
                return SignatureState.ValidSignature
            } catch {
                let nsError = error as NSError
                print(error)
                switch nsError.code {
                case 7: // no public key
                    return SignatureState.NoPublicKey
                case 8: // no signature
                    return SignatureState.NoSignature
                case 9: // unable to decrypt
                    return SignatureState.InvalidSignature
                default:
                    return SignatureState.InvalidSignature
                }
            }
        }
        return SignatureState.NoSignature
    }
    
    
    func vaildAddress(key: Key?) -> [String]{
        var adrs = [String]()
        if let k = key{
            if let pk = k.publicKey{
                let users = pk.users
                for user in users{
                    if let start = user.userID.range(of: "<"),
                        let end = user.userID.range(of: ">"){
                        let s = start.lowerBound
                        let e = end.upperBound
                        var adr = user.userID[s..<e]
                        if adr.count > 2{
                            adr = adr.substring(to: adr.index(before: adr.endIndex)) // remove >
                            adr.remove(at: adr.startIndex) // remove <
                        }
                        adr = adr.lowercased()
                        adrs.append(adr)
                    }
                }
            }
        }
        return adrs
    }
    
    func vaildAddress(keyId: String?) -> [String]{
        if let id = keyId{
            if let key = loadKey(id: id){
                return vaildAddress(key: key)
            }
        }
        return []
    }
    /*
         encrypt a array of strings with one password. Returns encrypted strings and the password for decryption
     */
	func symmetricEncrypt(textToEncrypt: [String]) -> (chiphers: [String], password: String){
        let password = generatePW(arc4: 8)
        var chiphers = [String]()
        
        for text in textToEncrypt{
            if let data = text.data(using: .utf8){
                if let chipher = try? ObjectivePGP.symmetricEncrypt(data, signWith: nil, encryptionKey: password, passphrase: password, armored: false){
					chiphers.append(chipher.base64EncodedString())
                }
            }
        }
        return (chiphers, password)
    }
    
    func symmetricDecrypt(chipherTexts: [String], password: String) -> [String]{
        var plaintexts = [String]()
        
        for chipher in chipherTexts{
            if let data = chipher.data(using: .utf8){
                if let plainData = try? ObjectivePGP.symmetricDecrypt(data, key: password, verifyWith: nil, signed: nil, valid: nil, integrityProtected: nil){
                    if let plainText = String(data: plainData, encoding: .utf8){
                        plaintexts.append(plainText)
                    }
                }
            }
        }
        return plaintexts
    }
}
