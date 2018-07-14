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

    var name: String {
        get {
            if let n = path.components(separatedBy: delimiter).last {
                return n
            }
            return path
        }
    }

    var counterMails: Int {
        get {
            if let mails = self.mails {
                return mails.count
            }
            return 0
        }
    }

    var frontendName: String {
        get {
            return UserManager.convertToFrontendFolderPath(from: name)
        }
    }

    var uids: MCOIndexSet {

        get {
            let ids = MCOIndexSet()
            for m in mailsOfFolder {
                ids.add(m.uid)
            }
            return ids
        }
    }



    var records: [KeyRecord] {
        get {
            if let keyRecords = keyRecords as? Set<KeyRecord> {
                return Array(keyRecords).sorted()
            }
            return []
        }

    }


    var mailsOfFolder: [PersistentMail] {
        get {
            var ms = [PersistentMail]()
            if let mymails = mails {
                if let m = mymails as? Set<PersistentMail> {
                    return Array(m)
                }
                for case let m as PersistentMail in mymails {
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
                if f.path.hasPrefix(path + delimiter) && f.path != path {
                    folders.append(f)
                }
            }
            return folders
        }
    }

    /*
    func updateRecords(mail: PersistentMail){
        if let reccords = storedRecords{
            if reccords.count <= 2{
                updateRecords()
                return
            }
            var founded = false
            for i in 1..<reccords.count {
                let r = reccords[i]
                if r.match(mail: mail){
                    founded = true
                    if r.mailsInFolder(folder: self).first == mail {
                        if reccords[i-1] > r {
                            storedRecords?.sort()
                            break
                        }
                    }
                }
            }
            if !founded && mail.folder == self{
                if mail.isSecure && mail.keyID != nil{
                    let record = KeyRecord(keyID: mail.keyID!, folder: self)
                    if !(storedRecords?.contains(record))!{
                        if record.mails.count > 0{
                            storedRecords?.append(record)
                        }
                    }
                }
                else {
                    let record = KeyRecord(contact: mail.from.contact!, folder: self)
                    if !(storedRecords?.contains(record))!{
                        if record.mails.count > 0{
                            storedRecords?.append(record)
                        }
                    }
                }
                storedRecords?.sort()
            }
        }
        else{
            if mail.folder == self{
                storedRecords = [KeyRecord]()
                if mail.isSecure && mail.keyID != nil{
                    let record = KeyRecord(keyID: mail.keyID!, folder: self)
                    storedRecords?.append(record)
                }
                else{
                    let record = KeyRecord(contact: mail.from.contact!, folder: self)
                    storedRecords?.append(record)
                }
            }
        }
    }
 */
}
