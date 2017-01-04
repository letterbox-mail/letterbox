//
//  State+CoreDataClass.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 04/01/17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import CoreData

@objc(State)
public class State: NSManagedObject {

    
    func getNumberOfMails()->Int{
        return Int(currentMails)
    }
    
    func setNumberOfMails(newValue: Int){
        currentMails = Int64(newValue)
    }
    
    func getNumberOfContacts()->Int{
        return Int(currentContacts)
    }
    
    func setNumberOfContacts(newValue: Int){
        currentContacts = Int64(newValue)
    }
    
    func setMaxUid(newValue: UInt64){
        maxUID = NSDecimalNumber.init(unsignedLongLong: newValue)
    }
    
    func getMaxUid()->UInt64{
        return maxUID.unsignedLongLongValue
    }
}
