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
    
    
    private func generatePW(size: Int)-> String{
        var pw = ""
        for i in 0..<size{
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
        let pw = generatePW(size: PasscodeSize)
        let key = gen.generate(for: "\(adr) <\(adr)>", passphrase: pw)
        pwKeyChain[key.keyID.longIdentifier] = pw
        return storeKey(key: key)
    }
    
    func importKeys (key: String,  pw: String?, isSecretKey: Bool, autocrypt: Bool) throws -> [String]{
        let pgp = ObjectivePGP()
        var keys = [Key]()
        if autocrypt{
           // let keyData = pgp.transformKey(key)
           // keys = pgp.importKeys(from: keyData)
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
                let m = try ObjectivePGP.sign("1234".data(using: .utf8)!, detached: false, using: [key], passphraseForKey: {(key) -> String? in return pw})
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
                       // var passcode = loadPassword(id: id)
                       // if passcode == nil{
                         //   passcode = generatePW(size: PasscodeSize)
                       // }
                       // exportPwKeyChain[key.keyID.longKeyString] = passcode
                       // let cipher = try! pgp.symmetricEncrypt(keyData, signWith: nil, encryptionKey: passcode, passphrase: passcode, armored: true)
                        
                        //return cipher
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
        var keys = [Key]()
        let signKey = loadKey(id: myId)
        for id in ids{
            if let key = loadKey(id: id){
                keys.append(key)
            }
        }
        if signKey != nil{
            keys.append(signKey!)
        }
        let signedAdr = vaildAddress(key: signKey)
        if let data = plaintext.data(using: String.Encoding.utf8){
            do{
                let chipher = try ObjectivePGP.encrypt(data, addSignature: true, using: keys, passphraseForKey: loadPassword)
                return CryptoObject(chiphertext: chipher, plaintext: plaintext, decryptedData: data, sigState: SignatureState.ValidSignature, encState: EncryptionState.ValidedEncryptedWithCurrentKey, signKey: myId, encType: CryptoScheme.PGP, signedAdrs: signedAdr)
            } catch {
                print("Encryption error!") //TODO: Error handling!
            }
        }
        return CryptoObject(chiphertext: nil, plaintext: nil,decryptedData: nil, sigState: SignatureState.InvalidSignature, encState: EncryptionState.UnableToDecrypt, signKey: nil, encType: cryptoScheme, signedAdrs: signedAdr)
        
    }
    
    func decrypt(data: Data,decryptionIDs: [String], verifyIds: [String], fromAdr: String?) -> CryptoObject{
        var cryptoObject: CryptoObject? = nil
        for decId in decryptionIDs{
            let temp = decrypt(data: data, decryptionId: decId, verifyIds: verifyIds, fromAdr: fromAdr)
            if temp.encryptionState != EncryptionState.UnableToDecrypt{
                cryptoObject = temp
                if decId != DataHandler.handler.prefSecretKey().keyID{
                    temp.encryptionState = EncryptionState.ValidEncryptedWithOldKey
                }
                else{
                    break
                }
            }
        }
        if let c = cryptoObject {
            return c
        }
        return decrypt(data: data, decryptionId: nil, verifyIds: verifyIds, fromAdr: fromAdr)
    }
    
    func decrypt(data: Data,decryptionId: String?, verifyIds: [String], fromAdr: String?) -> CryptoObject{
        var plaindata: Data? = nil
        var sigState = SignatureState.NoSignature
        var encState = EncryptionState.UnableToDecrypt
        var sigKeyID: String? = nil
        var signedAdr = [String]()
        var decKey: Key
        var encForCurrentSK = false
        var keys = [Key]()

        if let decIDs = try? ObjectivePGP.recipientsKeyID(forMessage: data){
            let currentSkID =  DataHandler.handler.prefSecretKey().keyID
            for id in decIDs{
                if let key = loadKey(id: id.longIdentifier){
                    decKey = key
                    keys.append(decKey)
                }
                if id.longIdentifier == currentSkID{
                    encForCurrentSK = true
                    break
                }
                
            }
        }
        
        if let plain = try? ObjectivePGP.decrypt(data, andVerifySignature: false, using: keys, passphraseForKey: loadPassword){
            plaindata = plain
            if encForCurrentSK{
                encState = EncryptionState.ValidedEncryptedWithCurrentKey
            }
            else{
                encState = EncryptionState.ValidEncryptedWithOldKey
            }
        }
        else{
            encState = EncryptionState.UnableToDecrypt
        }
        // test if message ist signed
        sigState = verifyMessage(data: data, keys: keys)
        for id in verifyIds{
            if let key = loadKey(id: id){
                keys.append(key)
                let currentState = verifyMessage(data: data, keys: keys)
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
        var plaintext: String? = nil
        if plaindata != nil{
            plaintext = plaindata?.base64EncodedString()
        }
        return CryptoObject(chiphertext: data, plaintext: plaintext, decryptedData: plaindata, sigState: sigState, encState: encState, signKey: sigKeyID, encType: CryptoScheme.PGP, signedAdrs: signedAdr)
    }
    
    private func verifyMessage(data: Data, keys: [Key]) -> SignatureState{
        do{
            try ObjectivePGP.verify(data, withSignature: nil, using: keys, passphraseForKey: loadPassword)
        } catch {
            let nsError = error as NSError
            switch nsError.code {
            case 7:
                return SignatureState.NoPublicKey
            case 8:
                return SignatureState.NoSignature
            case 9: // unable to decrypt
                return SignatureState.InvalidSignature
            default:
                return SignatureState.InvalidSignature
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
}
