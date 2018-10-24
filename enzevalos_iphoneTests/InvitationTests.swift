//
//  InvitationTests.swift
//  enzevalos_iphoneTests
//
//  Created by Konstantin Deichmann on 08.01.18.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
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

        XCTAssertEqual(firstResult?.words, "Diese")
        XCTAssertEqual(firstResult?.extendedRange, firstStringRange)

        XCTAssertEqual(secondResult?.words, "App hat viele")
        XCTAssertEqual(secondResult?.extendedRange, NSRange(location: 6, length: 13))
    }

    func testEncryptAndDecryptStrings() {

        let texts = ["Kontonummer", "DE 12345 625636 23", "Alice und Bob", "@~> ™", "12207", "🤨", "🤨 ABC123", "Hallo,\nwie geht es dir?🤨\n\nich bin hier und mir geht es gut"]
        let pgp = SwiftPGP()

        let encryption = pgp.symmetricEncrypt(textToEncrypt: texts, armored: true, password: nil)

        XCTAssertEqual(encryption.chiphers.count, texts.count)
        XCTAssertEqual(encryption.password.count, 9)

        let decryption = pgp.symmetricDecrypt(chipherTexts: encryption.chiphers, password: encryption.password)

        XCTAssertEqual(decryption, texts)
    }
}
