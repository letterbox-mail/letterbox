//
//  Folder+CoreDataClass.swift
//  
//
//  Created by Oliver Wiese on 05.07.17.
//
//

import Foundation
import CoreData

@objc(Folder)
public class Folder: NSManagedObject {

    var name: String{
        get{
            if let n = path.components(separatedBy: delimiter).last {
                return n
            }
            return path
        }
    }
    
    var frontendName: String {
        get {
            return UserManager.convertToFrontendFolderPath(from: name)
        }
    }
    
    var uids: MCOIndexSet{
    
        get{
            let ids = MCOIndexSet()
            for m in mailsOfFolder{
                ids.add(m.uid)
            }
            return ids
        }
    }
    
    var liveRecords: [KeyRecord]{
        get{
            var records = [KeyRecord]()
            // Get all Keys, get all adrs
            let keys = DataHandler.handler.allKeysInFolder(folder: self)
            let adrs = DataHandler.handler.allAddressesInFolder(folder: self, withoutSecure: true)
            
            for key in keys{
                let record = KeyRecord(keyID: key, folder: self)
                records.append(record)
            }
            for adr in adrs{
                if let ec = adr.contact{
                    let record = KeyRecord(contact: ec, folder: self)
                    records.append(record)
                }
            }
            return records.sorted()
        }
    }
    
    var records: [KeyRecord]? = nil
    
    var mailsOfFolder: [PersistentMail]{
        get{
            var ms = [PersistentMail]()
            if let mymails = mails{
                for case let m as PersistentMail in mymails{
                    ms.append(m)
                }
            }
            return ms
        }
    }
    
    var subfolders: [Folder] {
        get {
            var folders: [Folder] = []
            for f in DataHandler.handler.allFolders {
                if f.path.hasPrefix(path+delimiter) && f.path != path {
                    folders.append(f)
                }
            }
            return folders
        }
    }
    
    
    //write value of liveRecords to records
    func updateRecords() {
        records = liveRecords
    }
}
