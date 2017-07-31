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
            return UserManager.convertToFrontendFoldername(from: name)
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
    
    var records: [KeyRecord]{
        get{
            var records = [KeyRecord]()
            let mails = self.mailsOfFolder
            for m in mails {
                addToRecords(m, records: &records)
            }
            for r in records {
                r.mails.sort()
            }
            records.sort()
            print("Folder: \(self.name) with #KeyRecords: \(records.count) and \(mails.count) mails")
            return records
        }
    }
    
    
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
    
    private func addToRecords(_ m: PersistentMail, records: inout [KeyRecord]) {
        
        var found = false
        for r in records {
            if r.addNewMail(m) {
                found = true
                records.sort()
                break
            }
        }
        if !found {
            let r = KeyRecord(mail: m)
            mergeRecords(newRecord: r, records: &records)
            records.append(r)
            records.sort()
        }
    }
    
    
    private func mergeRecords(newRecord: KeyRecord, records: inout[KeyRecord]) {
        var j = 0
        if !newRecord.hasKey {
            return
        }
        while j < records.count {
            let r = records[j]
            if !r.hasKey && r.ezContact == newRecord.ezContact {
                var i = 0
                while i < r.mails.count {
                    let mail = r.mails[i]
                    var remove = false
                    if mail.from.keyID == newRecord.key {
                        remove = newRecord.addNewMail(mail)
                        if remove {
                            r.mails.remove(at: i)
                        }
                    }
                    if !remove {
                        i = i + 1
                    }
                }
                if r.mails.count == 0 {
                    records.remove(at: j)
                } else {
                    j = j + 1
                }
            } else {
                j = j + 1
            }
        }
    }
    
}
