//
//  Autocrypt.swift
//  enzevalos_iphoneTests
//
//  Created by Oliver Wiese on 01.11.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import XCTest
/**
 Test cases:
    * parse Header
    * parse examples and test cases (see: https://github.com/autocrypt/specs_data/tree/master/data)
    * Gossip
    * Secret key export
    * Secret key import
 */

@testable import enzevalos_iphone
class AutocryptTest: XCTestCase {
    let datahandler = DataHandler.handler
    let mailHandler = AppDelegate.getAppDelegate().mailHandler
    let pgp = SwiftPGP()
    let userAdr = "bob@enzevalos.de"
    let userName = "bob"
    var user: MCOAddress = MCOAddress.init(mailbox: "bob@enzevalos.de")
    var userKeyID: String = ""
    
    var simpleAutocryptExample: String{
        get{
            return
            """
            mQGNBFn+zzUBDADBo2D+WUbm3lN1lXtQTxLhxVADIIMLK1dFUgu5w1KAMrW0x9x27cRNxzVrTfiv
            2FiwThUHZmJBFai8HtsMvn/svrCPeGPvkjTDMCWZaEEc5/g51Uyszjf6fUsGXsC9tUcva6pGHaTe
            8Iwpz5stKjRKI3U/mPdQpXmaurwzEdvlNWNi9Ao2rwWV+BK3J/98gBRFT8W6gv+T/YGXVrqXMoMM
            KLTFze2uyO0ExJkhI64upJzD0HUbGjElYdeSWz7lYhQ2y5cmnWPfrnOxiOCVyKrgBulksda5SIjE
            qCJCVYprX/Wvh5feRXYftWVQUMeo6moNOhTM9X+zQJPWWuWivOJpamIuUCziEycX8RtRo0yAOPwc
            /vIppoxAMusQCVn15YwVECngzXUi3EB72wXJ4411VfzPCSlgVNZV7Yqx1lW4PMRcFB2oblO25rk3
            GDlmqEVcG1Hh4FtEBkmwVjiv4duN0E33r2Yf8OsFAkKnRCRllYn8409DaJGou41hEV+LAsUAEQEA
            AbQyYTFlYmQ2OGQtOGM3Ny00NWI4LWIwMzMtOGNhYzNmN2QyMDZkQGF1dG9jcnlwdC5vcmeJAc4E
            EwEIADgWIQTmBGjORNd8P86f0HJx28Vlf95lpwUCWf7PNQIbAwULCQgHAgYVCAkKCwIEFgIDAQIe
            AQIXgAAKCRBx28Vlf95lp3C/C/9tthB5Q6oyyjERPZmRY3V8n60wd0h35uLqQfcb51UYKZ3j+61n
            ckz2iB9LrRxY9Q31WozMqza+Jze4/g/VYHLlS7Zg0M3pLKzbSEyDvZVT523BVFsCQwjkq679JGZ/
            xPzJOPab1udXFsKPEfNvzKgK+x0a4Q8b03SemL5mmGPBrnuCza/nFhevUrQbbtuUzhBnMFBsPKvz
            WUTKHEgIDLqz+8auPOQZSbF2D/1BEvtbobdgQi+YJLaj77/pURR1kp7su51IffTs0qgMMJh8jwQY
            lMQMhozy43eqT1y9QE+DH9RBAYpcRCmTcBE5Z8apnWpH/axfCDjboWwD62gN0dawc7WEQ+rdgu8W
            Tocoo4A6iyCk6Xs59mOGE0gsCdZvzKruJOYqvERzeDibDc3hXDjOE82okBjQhsOVCK3a7uyAIZnc
            z9Kovi0CkQ9d3EuG8297HSf1/PupsiFgHBsJzmZ549+ZHLXlZ5ss4aj9Hpe7bCk8oUUL+A61+nNY
            VsVDSO25AY0EWf7PNQEMANI3/DkEjghl0SgsbzqHaUAohh+GSMXUD7dQn28ZGxR/2Y5wu7O5MdkP
            MKIrsyQowSeGn18rnM1PxnRGOrX+QnVZTdk73VeMID6nM1TTfv5gmkjcb6NphGPeOTZyJIbjgQxE
            z2LUbhFLseRS/6COF5q6Tj+TJFSPbDs5kVm8LqAra2vdvdpxV69WP2FfzwHIKTzxEwnDKc3rp7yE
            I52qz8xMTCO+IkBIc9rwdj7TqJxMOTZQdfpY/ltiGwg3lCGYaHuejJzDQlU/X6OCEq/WT7/UVqNw
            ZkrsT4uG9BFGW+WOXuOpgA4v0YQ62XQAotVNXUY10XFrSb6DTr6vYjd0Lk/z7icAX5uzjlfJN3TV
            qJxS0pDWtfYD52B936+mizGR+97uyqEBVNQKww1pvKdZDruiR43O0k63TMO/4cAhXfw7q91/RMGg
            TJX2UC/BGMiePziboP+GHX87hRmAvFCRjQc0KFyxJGbNKID3Kn/RhUrePCAVWI34lSQ0Do5qLlRn
            9QARAQABiQG2BBgBCAAgFiEE5gRozkTXfD/On9BycdvFZX/eZacFAln+zzUCGwwACgkQcdvFZX/e
            ZaeaIwv/WR2LYKlPXe/1sMKfh+iSYeJjvqx15i4OaLumont+btZmpyYDU8sOaMB12oBgQ3sNYaQp
            fkTk/QNw3lbuiROPJeANQzC7Ckj3SDBFoMXyqxmnzhH0P1qvT90VOB061P1aHg7usuU4+MuvLKrg
            vaLtzK4xuiHIzpkTCvtcyNmiS5Qi2guPV32UQ6HccSIEaZO5w+z6a/V0JZ19lVwOnOatUp4DsDHo
            4KfcUKpNUKoUGgkOhLP7DmsqdlnQoKCw4PxnSsg7H5imHKF1Xo/8nh0G5Wl5kpJendiI1ZGy/yES
            jN9i1kKSqL4X+R4PkT9foAootoK3TrLbcyHuxFj5umcUuqqGfsvjhgC/ZIyvvoRf4X0Bnn1h9hpo
            6ZvBoPDM5lJxtUL64Zx5HXLd6CQXGfZfZVeM+ODqQyITGQT+p7uMDiZF42DKiTyJjJHABgiV+J16
            IM4woaGfCwAU+0Vg+JDuf7Ec8iKx5UNDI18PJTTzGVp65Gvz2Mq/CHT/peFNHNqW
            """
        }
    }
    
    override func setUp() {
        super.setUp()
        datahandler.reset()
        pgp.resetKeychains()
        (user, userKeyID) = owner()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAutocryptHeader(){
        let outmail = OutgoingMail(toEntrys: ["alice@example.com"], ccEntrys: [], bccEntrys: [], subject: "subject", textContent: "Body", htmlContent: nil)
        if let parser = MCOMessageParser(data: outmail.plainData), let key = pgp.exportKey(id: userKeyID, isSecretkey: false, autocrypt: true) {
            let autocrypt = Autocrypt.init(header: parser.header)
            XCTAssertEqual(autocrypt.addr, userAdr)
            XCTAssertEqual(autocrypt.key.remove(seperatedBy: .whitespacesAndNewlines), key.remove(seperatedBy: .whitespacesAndNewlines))
            XCTAssertEqual(autocrypt.prefer_encryption, EncState.MUTUAL)
            do {
                let autoKeyIds = try pgp.importKeys(key: autocrypt.key, pw: nil, isSecretKey: false, autocrypt: true)
                if autoKeyIds.count > 0, let autoKeyId = autoKeyIds.first {
                    XCTAssertEqual(autoKeyId, userKeyID)
                }
                else {
                    XCTFail()
                }
            }
            catch {
                XCTFail()
            }
        }
        else {
            XCTFail()
        }
    }
    
    func testSpecExample(){
        let mailData = MailTest.loadMail(name: "autocryptSimpleExample1")
        if let parser = MCOMessageParser(data: mailData) {
            let autocrypt = Autocrypt.init(header: parser.header)
            XCTAssertEqual(autocrypt.addr, "alice@autocrypt.example")
            XCTAssertEqual(autocrypt.prefer_encryption, EncState.MUTUAL)
            XCTAssertEqual(autocrypt.key.remove(seperatedBy: .whitespacesAndNewlines), simpleAutocryptExample.remove(seperatedBy: .whitespacesAndNewlines))
            do {
                let autoKeyIds = try pgp.importKeys(key: autocrypt.key, pw: nil, isSecretKey: false, autocrypt: true)
                XCTAssertEqual(autoKeyIds.first, "71DBC5657FDE65A7")
            }
            catch {
                XCTFail()
            }
            print(autocrypt.toString())
        }
    }
    
    func createUser(adr: String = String.random().lowercased(), name: String = String.random()) -> MCOAddress {
        return MCOAddress.init(displayName: name, mailbox: adr.lowercased())
    }
    
    func createPGPUser(adr: String = String.random().lowercased(), name: String = String.random()) -> (MCOAddress, String) {
        let user = createUser(adr: adr, name: name)
        let id = pgp.generateKey(adr: user.mailbox)
        return (user, id)
    }
    
    func owner() -> (MCOAddress, String) {
        Logger.logging = false
        let (user, userid) = createPGPUser(adr: userAdr, name: userName)
        UserManager.storeUserValue(userAdr as AnyObject, attribute: Attribute.userAddr)
        UserManager.storeUserValue(userid as AnyObject, attribute: Attribute.prefSecretKeyID)
        return (user, userid)
    }
}
