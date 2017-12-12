//
//  PseudonymFolderPath+CoreDataProperties.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 06.12.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import Foundation
import CoreData

extension PseudonymFolderPath {
    
    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "PseudonymFolderPath");
    }
    
    @NSManaged public var pseudonym: String
    @NSManaged public var folderPath: String
}
