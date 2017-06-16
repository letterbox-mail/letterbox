//
//  MailAddress.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 10/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import Contacts

public enum EncState {
    case MUTAL
    case GOSSIP
    case NOPREFERENCE
    case RESET
    case NOAUTOCRYPT
    
    
    static func find(i: Int) -> EncState{
        switch i {
        case 0:
            return EncState.MUTAL
        case 1:
            return EncState.GOSSIP
        case 2:
            return EncState.NOPREFERENCE
        case 3:
            return EncState.RESET
        case 4:
            return EncState.NOAUTOCRYPT
        default:
            return EncState.NOAUTOCRYPT
        }
    }
    
    func canEnc() -> Bool{
        
        switch self {
        case EncState.MUTAL:
            return true
        case EncState.GOSSIP:
            return true
        case EncState.RESET:
            return true
        default:
            return false
        }
    }
    func asInt()-> Int16{
        switch self {
        case EncState.MUTAL:
            return 0
        case EncState.GOSSIP:
            return 1
        case EncState.NOPREFERENCE:
            return 2
        case EncState.RESET:
            return 3
        case EncState.NOAUTOCRYPT:
            return 4
        }
    }

}

public protocol MailAddress { 
    var mailAddress:String{get}
    var label: CNLabeledValue<NSString>{get} //FIXME: ist der NSString hier wirklich richtig? (http://stackoverflow.com/questions/39648830/how-to-add-new-email-to-cnmutablecontact-in-swift-3)
    var prefEnc: EncState{get set}
    var hasKey: Bool{get}
    
    var keyID: String?{get}
    var contact: EnzevalosContact?{get}
}
