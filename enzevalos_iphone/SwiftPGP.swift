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
    
    private func storeKey(key: PGPKey) -> String{
        let id = key.keyID.longKeyString
        let data = try! key.export()
        if let testData = try? keychain.getData(id), testData != nil{
            // merge keys. i.e. secret key stored and key is public key.
            let pgp = ObjectivePGP()
            pgp.importKeys(from: testData!)
            pgp.importKeys(Set([key]))
            let key = pgp.findKey(for: key.keyID)
            let newData = try! key?.export()
            keychain[data: id] = newData
        }
        else{
            keychain[data: id] = data
        }
        return id
    }
    
    func loadKey(id: String) -> PGPKey?{
        do{
            if let data = try keychain.getData(id){
                let pgp = ObjectivePGP()
                let keys = pgp.keys(from: data)
                if let key = keys.first{
                    return key
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
    
    func generateKey(adr: String) -> String{
        let gen = PGPKeyGenerator()
        let pw = generatePW(size: PasscodeSize)
        let key = gen.generate(for: "\(adr)<\(adr)>", passphrase: pw)
        pwKeyChain[key.keyID.longKeyString] = pw
        return storeKey(key: key)
    }
    
    func importKeys(key: String,  pw: String?, isSecretKey: Bool, autocrypt: Bool) -> [String]{
        let pgp = ObjectivePGP()
        let keys: Set<PGPKey>
        if autocrypt{
            let keyData = pgp.transformKey(key)
            keys = pgp.importKeys(from: keyData)
        }
        else{
            if let data = key.data(using: .utf8){
                keys = pgp.importKeys(from: data) 
                
            }
            else{
                keys = Set<PGPKey>()
            }
        }
        return storeMultipleKeys(keys: keys, pw: pw, secret: isSecretKey)
    }
    
    func importKeys(data: Data,  pw: String?, secret: Bool) -> [String]{
        let pgp = ObjectivePGP()
        let keys = pgp.importKeys(from: data)
        return storeMultipleKeys(keys: keys, pw: pw, secret: secret)
    }

    
    func importKeysFromFile(file: String,  pw: String?) -> [String]{
        let pgp = ObjectivePGP()
        let keys = pgp.importKeys(fromFile: file)
        return storeMultipleKeys(keys: keys, pw: pw, secret: false)
    }
    
    private func storeMultipleKeys(keys: Set<PGPKey>, pw: String?, secret: Bool )-> [String]{
        var ids = [String]()
        for k in keys{
            if k.isSecret && secret || !k.isSecret && !secret{
                ids.append(storeKey(key: k))
                if let password = pw{
                    pwKeyChain[k.keyID.longKeyString] = password
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
        let pgp = ObjectivePGP()
        if var key = loadKey(id: id){
            if isSecretkey && key.isSecret{
                if let keyData = pgp.export(key, armored: true){
                    if autocrypt{
                        // Create Autocrypt Setup-message
                        // See: https://autocrypt.readthedocs.io/en/latest/level1.html#autocrypt-setup-message
                        var passcode = loadPassword(id: id)
                        if passcode == nil{
                            passcode = generatePW(size: PasscodeSize)
                        }
                        exportPwKeyChain[key.keyID.longKeyString] = passcode
                        let cipher = try! pgp.symmetricEncrypt(keyData, signWith: nil, encryptionKey: passcode, passphrase: passcode, armored: true)
                        print(String.init(data: cipher, encoding: .utf8) ?? "NO KEY")
                        
                        return cipher
                    }
                    return keyData
                }
            }            
            if key.isSecret && !isSecretkey{
                var pk: Data
                do {
                    pk = try key.export(PGPPartialKeyType.public, error: ())
                    let keys = pgp.keys(from: pk)
                    if (keys.count > 0){
                        key = keys.first!
                    }
                    else{
                        return nil
                    }
                } catch {
                    return nil
                }
               
            }
            if autocrypt{
                if let data = pgp.export(key, armored: false){
                    return data
                }
            }
            else{
                if let data = pgp.export(key, armored: true){
                    return data
                }
            }
        }
        return nil
    }

    
    func encrypt(plaintext: String, ids: [String], myId: String) -> CryptoObject{
        let pgp = ObjectivePGP()
        let pw = loadPassword(id: myId)
        var keys = [PGPKey]()
        let signKey = loadKey(id: myId)
        for id in ids{
            if let key = loadKey(id: id){
                keys.append(key)
            }
        }
        let signedAdr = vaildAddress(key: signKey)
        if let data = plaintext.data(using: String.Encoding.utf8){
            do{
                let chipher = try pgp.encryptData(data, using: keys, signWith: signKey, passphrase: pw, armored: true)
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
        let pgp = ObjectivePGP()
        var pw: String? = nil
        var signedAdr = [String]()
        if let myId = decryptionId{
            pw = loadPassword(id: myId)
        }

        //has to be var because it is given as pointer to obj-c-code
        var signed = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        signed[0] = false
        //has to be var because it is given as pointer to obj-c-code
        var valid = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        valid[0] = false

        var plaindata: Data? = nil
        var sigState = SignatureState.NoSignature
        var encState = EncryptionState.UnableToDecrypt //TODO: More decryption keys?
        var sigKey: String? = nil
        
        if let decId = decryptionId{
            if let decKey = loadKey(id: decId){
                pgp.importKeys(Set([decKey]))
            }
            //else{
             //   return CryptoObject(chiphertext: data, plaintext: nil, sigState: SignatureState.NoSignature, encState: EncryptionState.UnableToDecrypt, signKey: nil, encType: CryptoScheme.PGP)
           // }
        }
        for id in verifyIds{
            let key = loadKey(id: id)
            do{
                plaindata = try pgp.decryptData(data, passphrase: pw, verifyWith: key, signed: signed, valid: valid, integrityProtected: nil)
                encState = EncryptionState.ValidedEncryptedWithCurrentKey
                if !signed.pointee.boolValue{
                    break
                }
                else if signed.pointee.boolValue && valid.pointee.boolValue{
                    sigState = SignatureState.ValidSignature
                    sigKey = id
                    signedAdr = vaildAddress(keyId: sigKey)
                    if fromAdr != nil && !signedAdr.contains(fromAdr!){
                        sigState = SignatureState.InvalidSignature
                    }
                    break
                }
                else{
                    sigState = SignatureState.InvalidSignature
                }
            }catch{
                encState = EncryptionState.UnableToDecrypt
                sigState = SignatureState.InvalidSignature
                break
            }
        }
        
        if encState == EncryptionState.UnableToDecrypt{
            //TODO: What about old signature keys?
            //TODO: Test
            do{
                plaindata = try pgp.decryptData(data, passphrase: nil)
                encState = EncryptionState.ValidedEncryptedWithCurrentKey
                sigState = SignatureState.InvalidSignature //TODO: No signature???
            }catch{
                encState = EncryptionState.UnableToDecrypt
            }
        }
        
        var plaintext: String? = nil
        if plaindata != nil{
            plaintext = plaindata?.base64EncodedString()
        }
        return CryptoObject(chiphertext: data, plaintext: plaintext, decryptedData: plaindata, sigState: sigState, encState: encState, signKey: sigKey, encType: CryptoScheme.PGP, signedAdrs: signedAdr)
    }
    
    
    func vaildAddress(key: PGPKey?) -> [String]{
        var adrs = [String]()
        if let k = key{
            if let pk = k.publicKey{
                let users = pk.users
                for user in users{
                    if let start = user.userID.range(of: "<"),
                        let end = user.userID.range(of: ">"){
                        let s = start.lowerBound
                        let e = end.upperBound
                        let adr = user.userID[s..<e]
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
