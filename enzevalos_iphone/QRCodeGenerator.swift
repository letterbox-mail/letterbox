//
//  QRCodeGenerator.swift
//  enzevalos_iphone
//
//  Created by Joscha on 01.08.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
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
