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
    
    private var keychain: Keychain{
        get{
            return Keychain(service: "Enzevalos/PGP")
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
    
    func generateKey(adr: String) -> String{
        let gen = PGPKeyGenerator()
        let key = gen.generate(for: adr, passphrase: nil)
        return storeKey(key: key)
    }
    
    func importKeys(key: String, isSecretKey: Bool, autocrypt: Bool) -> [String]{
        let pgp = ObjectivePGP()
        var ids = [String]()
        let keys: Set<PGPKey>
        if autocrypt{
            keys = pgp.importKeys(from: key)
        }
        else{
            if let data = key.data(using: .utf8){
                keys = pgp.importKeys(from: data) //.base64EncodedData()
                
            }
            else{
                keys = Set<PGPKey>()
            }
        }
        for k in keys{
            if k.isSecret && isSecretKey || !k.isSecret && !isSecretKey{
                ids.append(storeKey(key: k))
            }
        }
        return ids
    }
    
    func importKeysFromFile(file: String) -> [String]{
        let pgp = ObjectivePGP()
        let keys = pgp.importKeys(fromFile: file)
        var ids = [String]()
        for k in keys{
            ids.append(storeKey(key: k))
        }
        return ids
    }
    
    func exportKey(id: String, isSecretkey isSecretKey: Bool, autocrypt: Bool) -> String?{
        let pgp = ObjectivePGP()
        if var key = loadKey(id: id){
            if key.isSecret && !isSecretKey{
                let pk = try! key.export(PGPPartialKeyType.public, error: ())
                let keys = pgp.keys(from: pk)
                if (keys.count > 0){
                    key = keys.first!
                }
                else{
                    return nil
                }
            }
            if autocrypt{
                if let data = pgp.export(key, armored: false){
                    return data.base64EncodedString()
                }
            }
            else{
                if let data = pgp.export(key, armored: true){
                    return data.base64EncodedString()
                }
            }
        }
        return nil
    }
    
    func encrypt(plaintext: String, ids: [String], myId: String) -> CryptoObject{
        let pgp = ObjectivePGP()
        var keys = [PGPKey]()
        let signKey = loadKey(id: myId)
        for id in ids{
            if let key = loadKey(id: id){
                keys.append(key)
            }
        }
        if let data = plaintext.data(using: String.Encoding.utf8){
            do{
                let chipher = try pgp.encryptData(data, using: keys, signWith: signKey, passphrase: nil, armored: true)
                return CryptoObject(chiphertext: chipher, plaintext: plaintext, decryptedData: data, sigState: SignatureState.ValidSignature, encState: EncryptionState.ValidedEncryptedWithCurrentKey, signKey: myId, encType: CryptoScheme.PGP)
            } catch {
                print("Encryption error!") //TODO: Error handling!
            }
        }
        return CryptoObject(chiphertext: nil, plaintext: nil,decryptedData: nil, sigState: SignatureState.InvalidSignature, encState: EncryptionState.UnableToDecrypt, signKey: nil, encType: cryptoScheme)
        
    }
    func decrypt(data: Data,decryptionId: String?, verifyIds: [String]) -> CryptoObject{
        let pgp = ObjectivePGP()
        
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
                plaindata = try pgp.decryptData(data, passphrase: nil, verifyWith: key, signed: signed, valid: valid, integrityProtected: nil)
                encState = EncryptionState.ValidedEncryptedWithCurrentKey
                if !signed.pointee.boolValue{
                    break
                }
                else if signed.pointee.boolValue && valid.pointee.boolValue{
                    sigState = SignatureState.ValidSignature
                    sigKey = id
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
            print("Plaintext: plaintext")
        }
        else{
            print("No plaintext!")
        }
        return CryptoObject(chiphertext: data, plaintext: plaintext, decryptedData: plaindata, sigState: sigState, encState: encState, signKey: sigKey, encType: CryptoScheme.PGP)
    }
}
