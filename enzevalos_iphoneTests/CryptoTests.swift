//
//  CryptoTests.swift
//  enzevalos_iphoneTests
//
//  Created by Oliver Wiese on 26.03.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import XCTest

@testable import enzevalos_iphone
class CryptoTests: XCTestCase {
    
    //TODO: test importkey: public, autocrypt
    //      test export key: public, secret
    //      implement signature check
    
    let datahandler = DataHandler.handler
    let pgp = SwiftPGP()
    
    let userAdr = "alice@example.com"
    let userName = "alice"
    var user: MCOAddress = MCOAddress.init(mailbox: "alice@example.com")
    var userKeyID: String = ""
    
    static let importPW = "alice"
    static let importKey = """
    -----BEGIN PGP PUBLIC KEY BLOCK-----

    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
    aw==
    =fXJ3
    -----END PGP PUBLIC KEY BLOCK-----
    -----BEGIN PGP PRIVATE KEY BLOCK-----

    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
    =U2bk
    -----END PGP PRIVATE KEY BLOCK-----
    """
    
    let keyForSignedMessage = """
    -----BEGIN PGP PUBLIC KEY BLOCK-----

    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
    gXhCQhUXVfrkXAAQg+jrg04=
    =XzWc
    -----END PGP PUBLIC KEY BLOCK-----
    -----BEGIN PGP PRIVATE KEY BLOCK-----

    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
    =5SSn
    -----END PGP PRIVATE KEY BLOCK-----

    """
    
    let signedMessage = """
    -----BEGIN PGP SIGNATURE-----

    iQGzBAEBCgAdFiEEJRxNIIPfYdSrprTDTbvambTX/SgFAlq5A9oACgkQTbvambTX
    /SgIWwwAm1BTBjme8ogPdKcj2fyAzLjWPwttIW3nJN/tlB79TcId2sAAZK0hyhJQ
    PU+j72x0IrgnJ0Vf40B9QU07RgLtdJPXXN1GWQPaz/69Wiut4T6mUusiqfE4RLiy
    HJF7OYUNY6adteO1jCm0ZiZl3VW6XVomaXNuZtqXE+4U2k4WyQvaGbYMNvaaAYRf
    vwYLyj/CO6++7lhYDet+A4OE5w0WcRHqrM4IRs/wF62cgBVl9cnonvl/2MTgR6DX
    ewEcAeF+BmtMfVZhjEUa/zslLRTCRaxpVCq6BjHydakCTpZCJJTQcm+gVZrtQjl0
    953zPJUfJ1/pvUextyKihT9a5itsxV2Tboq0mwD09M+hqWlHy0lQujI/hggcVvxE
    DudoBwBZ4TilZyfRaSb9no1lJjxTZhwtsAvwOSPhRs3pGxkL9TS4GmqSsl8vZUBt
    LBNFaFMvJfDXqmwIcW1Yl+apk7bWqY7yfTCgdRzhcqFDxdqhchNYvq4x035z4Udz
    ZMarcccr
    =OmRP
    -----END PGP SIGNATURE-----
    """
    
    let manipulatedSignedMail = """
    -----BEGIN PGP SIGNATURE-----

    iQGzBAEBCgAdFiEEJRxNIIPfYdSrprTDTbvambTX/SgFAlq5A9oACgkQTbvambTX
    /SgIWwwAm1BTBjme8ogPdKcj2fyAzLjWPwttIW3nJN/tlB79TcId2sAAZK0hyhJQ
    PU+j72x0IrgnJ0Vf40B9QU07RgLtdJPXXN1GWQPaz/69Wiut4T6mUusiqfE4RLiy
    HJF7OYUNY6adteO1jCm0ZiOl3VW6XVomaXNuZtqXE+4U2k4WyQvaGbYMNvaaAYRf
    vwYLyj/CO6++7lhYDet+A4OE5w0WcRHqrM4IRs/wF62cgBVl9cnonvl/2MTgR6DX
    ewEcAeF+BmtMfVZhjEUa/zslLRTCRaxpVCq6BjHydakCTpZCJJTQcm+gVZrtQjl0
    953zPJUfJ1/pvUextyKihT9a5itsxV2Tboq0mwD09M+hqWlHy0lQujI/hggcVvxE
    DudoBwBZ4TilZyfRaSb9no1lJjxTZhwtsAvwOSPhRs3pGxkL9TS4GmqSsl8vZUBt
    LBNFaFMvJfDXqmwIcW1Yl+apk7bWqY7yfTCgdRzhcqFDxdqhchNYvq4x035z4Udz
    ZMarcccr
    =OmRP
    -----END PGP SIGNATURE-----
    """
    
    
    override func setUp() {
        super.setUp()
        datahandler.reset()
        pgp.resetKeychains()
        (user, userKeyID) = owner()
    }
    
    override func tearDown() {
        datahandler.reset()
        super.tearDown()
    }
    
    func createUser(adr: String = String.random().lowercased(), name: String = String.random()) -> MCOAddress{
        return MCOAddress.init(displayName: name, mailbox: adr.lowercased())
    }
    
    func createPGPUser(adr: String = String.random().lowercased(), name: String = String.random()) -> (address: MCOAddress, keyID: String){
        let user = createUser(adr: adr, name: name)
        let id = pgp.generateKey(adr: user.mailbox)
        return (user, id)
    }
    
    func owner() -> (MCOAddress, String){
        Logger.logging = false
        let (user, userid) = createPGPUser(adr: userAdr, name: userName)
        UserManager.storeUserValue(userAdr as AnyObject, attribute: Attribute.userAddr)
        UserManager.storeUserValue(userid as AnyObject, attribute: Attribute.prefSecretKeyID)
        return (user, userid)
    }
    
    func createSender(n: Int)-> [MCOAddress:String]{
        var result = [MCOAddress:String]()
        
        for _ in 1...n{
            let adr = String.random()
            let name = String.random()
            
            let (mcoaddr, id) =  createPGPUser(adr: adr, name: name)
            result[mcoaddr] = id
        }
        return result
    }
    
    func testKeyGen(){
        guard let key = pgp.loadKey(id: userKeyID) else {
            XCTFail("No key")
            return
        }
        guard let pk = key.publicKey else {
            XCTFail("No public key")
            return
        }
        XCTAssertTrue(key.isPublic && key.isSecret)
        var containsAddr = false
        for user in pk.users {
            if user.userID.contains(userAdr){
                containsAddr = true
            }
            else{
                XCTFail("userID does not contain userAddr")
            }
        }
        XCTAssertTrue(containsAddr)
    }
    
    func testimportSecretKey(){
        XCTAssert(datahandler.prefSecretKey().keyID == userKeyID)
        XCTAssertEqual(datahandler.findSecretKeys().count, 1)
        guard let keys = try? pgp.importKeys(key: CryptoTests.importKey, pw: CryptoTests.importPW, isSecretKey: true, autocrypt: false) else {
            XCTFail("No key")
            return
        }
        guard let key = keys.first else {
            XCTFail("no key")
            return
        }
        XCTAssert(keys.count == 1)
        XCTAssert(key == "008933003B986364")
        
        // Test storing a key
        _ = datahandler.newSecretKey(keyID: key, addPk: true)
        XCTAssert(datahandler.prefSecretKey().keyID == key)
        XCTAssertNotNil(datahandler.findSecretKey(keyID: key))
        XCTAssertEqual(datahandler.findSecretKeys().count, 2)

    }
    
    func testPlainMail(){
        let body = "plain message"
        guard let data = body.data(using: .utf8) else {
            XCTFail("No data")
            return 
        }
        let cryptoObject = pgp.decrypt(data: data, decryptionId: userKeyID, verifyIds: [], fromAdr: nil)
        XCTAssert(cryptoObject.encryptionState == .NoEncryption)
        XCTAssert(cryptoObject.signatureState == .NoSignature)
        XCTAssert(cryptoObject.decryptedData == nil && cryptoObject.decryptedText == nil && cryptoObject.signKey == nil)
        XCTAssert(cryptoObject.plaintext == body)
    }
    
    func testEncMail(){
        let body = "encrypted text"
        let senderPGP = SwiftPGP()
        let encryptedObject = senderPGP.encrypt(plaintext: body, ids: [userKeyID], myId: "")
        XCTAssert(encryptedObject.encryptionState == .ValidedEncryptedWithCurrentKey && encryptedObject.signatureState == .NoSignature)
        
        guard let data = encryptedObject.chiphertext else {
            XCTFail("No chipher data")
            return
        }        
        let cryptoObject = pgp.decrypt(data: data, decryptionId: userKeyID, verifyIds: [], fromAdr: nil)
        XCTAssert(cryptoObject.encryptionState == .ValidedEncryptedWithCurrentKey)
        XCTAssert(cryptoObject.signatureState == .NoSignature)
        XCTAssert(cryptoObject.plaintext == body && cryptoObject.plaintext == cryptoObject.decryptedText)
    }
    
    func testSignedMail(){
        // import keys and data for signature test
        guard let keys = try? pgp.importKeys(key: keyForSignedMessage, pw: nil, isSecretKey: true, autocrypt: false), keys.count > 0 else {
            XCTFail("Can not import key")
            return
        }
        guard let signedData = signedMessage.data(using: .utf8), let manipulatedDate = manipulatedSignedMail.data(using: .utf8) else{
            XCTFail("No signed data")
            return
        }
        
        // 1. case: correct signed mail
        var cryptoObject = pgp.decrypt(data: signedData, decryptionId: keys.first, verifyIds: keys, fromAdr: nil)
        XCTAssert(cryptoObject.encryptionState == .NoEncryption && cryptoObject.signatureState == .ValidSignature)
        XCTAssert(cryptoObject.decryptedText == "only a signed mail!")
        
        // 2. case: manipulated mail
        cryptoObject = pgp.decrypt(data: manipulatedDate, decryptionId: keys.first, verifyIds: keys, fromAdr: nil)
        XCTAssert(cryptoObject.encryptionState == .NoEncryption && cryptoObject.signatureState == .InvalidSignature)
    }
    
    func testEncSignedMail(){
        let body = "signed text"
        let (senderAddress, senderID) = createPGPUser()
        let (_, id2) = createPGPUser()

        let senderPGP = SwiftPGP()
        let encObject = senderPGP.encrypt(plaintext: body, ids: [userKeyID], myId: senderID)
        XCTAssert(encObject.encryptionState == .ValidedEncryptedWithCurrentKey && encObject.signatureState == SignatureState.ValidSignature )
        let falseEncObject = senderPGP.encrypt(plaintext: body, ids: [], myId: senderID)
        
        guard let data = encObject.chiphertext, let data2 = falseEncObject.chiphertext else {
            XCTFail("no chipher data")
            return
        }
        // 1. case: signed but no public key available to verify signature
        var cryptoObject = pgp.decrypt(data: data, decryptionId: userKeyID, verifyIds: [], fromAdr: nil)
        XCTAssert(cryptoObject.encryptionState == .ValidedEncryptedWithCurrentKey)
        XCTAssert(cryptoObject.signatureState == .NoPublicKey)
        XCTAssert(cryptoObject.plaintext == body && cryptoObject.plaintext == cryptoObject.decryptedText)
        
        // 2. case: signed and public key available
        cryptoObject = pgp.decrypt(data: data, decryptionId: userKeyID, verifyIds: [senderID, id2], fromAdr: nil)
        XCTAssert(cryptoObject.signatureState == .ValidSignature)
        XCTAssert(cryptoObject.signKey == senderID)
        XCTAssert(cryptoObject.signedAdrs.contains(senderAddress.mailbox) && cryptoObject.signedAdrs.count == 1)
    
        // 3. case: signed and check with wrong key
        cryptoObject = pgp.decrypt(data: data, decryptionId: userKeyID, verifyIds: [id2], fromAdr: nil)
        XCTAssert(cryptoObject.signatureState == .NoPublicKey)
       
        // 4. case: can not decrypt (wrong/missing decryption/encryption key)
        cryptoObject = pgp.decrypt(data: data2, decryptionId: userKeyID, verifyIds: [senderID], fromAdr: nil)
        XCTAssert(cryptoObject.encryptionState == .UnableToDecrypt && cryptoObject.signatureState == .NoSignature)

        // 5. case: used old key to encrypt message
        // Import a new secret key -> previous key is now an old key
        guard let keys = try? pgp.importKeys(key: CryptoTests.importKey, pw: CryptoTests.importPW, isSecretKey: true, autocrypt: false), keys.count > 0 else {
            XCTFail("Can not import key")
            return 
        }
        XCTAssertEqual(keys.count, 1)
        _ = datahandler.newSecretKeys(keyIds: keys, addPKs: true)
        XCTAssertEqual(keys.first, datahandler.prefSecretKey().keyID)
        cryptoObject = pgp.decrypt(data: data, decryptionId: userKeyID, verifyIds: [senderID], fromAdr: nil)
        XCTAssertEqual(keys.first, datahandler.prefSecretKey().keyID)
        XCTAssert(cryptoObject.encryptionState == .ValidEncryptedWithOldKey && cryptoObject.signatureState == .ValidSignature)
        XCTAssert(cryptoObject.decryptedText == body)
    }

    
}
