//
//  QRCodeGenerator.swift
//  enzevalos_iphone
//
//  Created by Joscha on 01.08.17.
//  Copyright © 2018 fu-berlin.
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
// https://www.appcoda.com/qr-code-generator-tutorial/

import Foundation

class QRCode {

    static func generate(input: String) -> CIImage {
        var qrCode: CIImage

        let data = input.data(using: String.Encoding.isoLatin1)
        let filter = CIFilter(name: "CIQRCodeGenerator")!

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        qrCode = filter.outputImage!

        return qrCode
    }
}
