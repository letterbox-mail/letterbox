//
//  test_store_data.swift
//  enzevalos_iphone
//
//  Created by Oliver Wiese on 27/12/16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation
import CoreData
import UIKit



var contacts: [EnzevalosContact] = []


func save(name: String) {
    
    guard let appDelegate =
        UIApplication.shared.delegate as? AppDelegate else {
            return
    }
    
    // 1
    let managedContext =
        appDelegate.persistentContainer.viewContext
    
       let person = EnzevalosContact(context: managedContext)
    // 3
    person.setValue(name, forKeyPath: "name")
    
    // 4
    do {
        try managedContext.save()
        contact.append(person)
    } catch let error as NSError {
        print("Could not save. \(error), \(error.userInfo)")
    }
}
