//
//  InvitationTests.swift
//  enzevalos_iphoneTests
//
//  Created by Konstantin Deichmann on 08.01.18.
//  Copyright © 2018 fu-berlin. All rights reserved.
//

import XCTest

@testable import enzevalos_iphone

class InvitationTests: XCTestCase {

	func testWordsInString() {

		let string = "Diese App hat viele Vorteile"
		let firstStringRange = NSRange(location: 0, length: 5)
		let secondStringRange = NSRange(location: 7, length: 9)

		let firstResult = string.words(inRange: firstStringRange)
		let secondResult = string.words(inRange: secondStringRange)

		print(firstResult)
		XCTAssertEqual(firstResult.count, 1)
		XCTAssertEqual(firstResult.first?.word, "Diese")
		XCTAssertEqual(firstResult.first?.index, 0)

		print(secondResult)
		XCTAssertEqual(secondResult.count, 3)
		XCTAssertEqual(secondResult[0].word, "App")
		XCTAssertEqual(secondResult[1].word, "hat")
		XCTAssertEqual(secondResult[2].word, "viele")
		XCTAssertEqual(secondResult[0].index, 6)
		XCTAssertEqual(secondResult[1].index, 10)
		XCTAssertEqual(secondResult[2].index, 14)
	}

	func testEncryptAndDecryptStrings() {

		let texts = ["Kontonummer", "DE 12345 625636 23", "Alice und Bob", "PLZ", "12207", "🤨", "🤨 ABC123"]
		let pgp = SwiftPGP()

		let encryption = pgp.symmetricEncrypt(textToEncrypt: texts)

		XCTAssertEqual(encryption.chiphers.count, texts.count)
		XCTAssertEqual(encryption.password.count, 8)

		let decryption = pgp.symmetricDecrypt(chipherTexts: encryption.chiphers, password: encryption.password)

		XCTAssertEqual(decryption, texts)
	}
}
