//
//  EncryptionType.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 13.01.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

public enum EncryptionType : String {
    case unknown = "unknown", PGP = "PGP"
    
    var autocryptSymbol: String{
        switch self {
        case .PGP:
            return "1"
        default:
            return ""
        }
        
    }
    
    static func typeFromAutocrypt(_ symbol: String)-> EncryptionType{
        switch symbol {
        case "1":
            return .PGP
        default:
            return .unknown
        }
    }
    
    static func fromString(_ string: String?)->EncryptionType{
        if let symbol = string{
            switch symbol {
            case "PGP":
                return .PGP
            case "1":
                return .PGP
            default:
                return .unknown
            }
        }
        return .unknown
    }
}
