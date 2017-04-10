//
//  LogHandler.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 30.10.16.
//  Copyright © 2016 fu-berlin. All rights reserved.
//

import Foundation
import UIKit

class LogHandler {
    
    private static var defaults = UserDefaults.init()
    private(set) static var logging = false
    private static var date = Date.init()
    static var session : Int = 0
    
    static func newLog(){
        logging = true
        session = defaults.integer(forKey: "Session")
        if session == 0{
            session = 1
        }
        else {
            session += 1
        }
        defaults.set(session, forKey: "Session")
        defaults.set(0, forKey: String(session)+"-index")
        defaults.set("time,caller,interaction,point,comment"/*"time,caller,interaction,point,debugDescription,comment"*/, forKey: String(session)+"-0")
        date = Date.init()
        defaults.set(date.description, forKey: String(session)+"-date")
        print("Logging Session: ",session)
        print(date.description)
    }
    
    static func stopLogging(){
        logging = false
    }
    
    //TODO: escaping in comment and debugDescription
    static func doLog(_ caller: String?, interaction: String, point: CGPoint, /*debugDescription: String,*/ comment : String){
        var entry = ""
        let now = Date.init()
        //Zeit holen
        entry.append(String(now.timeIntervalSince(date)))
        entry.append(",")
        //caller identifizieren
        if caller != nil{
            entry.append(caller!)
        }
        entry.append(",")
        //interaction bestimmen
        entry.append(interaction)
        entry.append(",")
        //Punkt anbinden
        entry.append(String(describing: point))
        entry.append(",")
        //debugDescription anhängen
        //entry.appendContentsOf(debugDescription)
        //entry.appendContentsOf(",")
        //text anbinden
        entry.append(comment)
        //in nsuserdefaults speichern
        var index = defaults.integer(forKey: String(session)+"-index")
        index += 1
        defaults.set(index, forKey: String(session)+"-index")
        defaults.set(entry, forKey: String(session)+"-"+String(index))
    }
    
    //methode zum auslesen eines logs
    static func printLog(_ session : Int){
        print()
        print("--------------------LOG OUTPUT--------------------")
        print("LoggingSession ",session)
        print(defaults.object(forKey: String(session)+"-date"))
        print()
        for i in 0 ..< defaults.integer(forKey: String(session)+"-index")+1{
            if let entry = defaults.object(forKey: String(session)+"-"+String(i)) {
                    print(String(describing: entry))
            }
            else {
                print(",,,,")//print(",,,,,")
            }
        }
        print()
        print("--------------------------------------------------")
        print()
        print()
    }
    
    static func printLogs(){
        for i in 1 ..< defaults.integer(forKey: "Session")+1 {
            printLog(i)
        }
    }
    
    static func getLog(_ session : Int) -> String{
        var log = "\n--------------------LOG OUTPUT--------------------\nLoggingSession "+String(session)+"\n"+String(describing: defaults.object(forKey: String(session)+"-date"))+"\n\n"
        
        for  i in 0 ..< defaults.integer(forKey: String(session)+"-index")+1{
            if let entry = defaults.object(forKey: String(session)+"-"+String(i)) {
                log.append(String(describing: entry)+"\n")
            }
            else {
                log.append(",,,,\n")//log.appendContentsOf(",,,,,\n")
            }
        }
        log.append("\n--------------------------------------------------\n\n")
        
        return log
    }
    
    static func getLogs() -> String {
        var logs = ""
        for i in 1 ..< defaults.integer(forKey: "Session")+1 {
            logs.append(getLog(i))
        }
        return logs
    }
    
    //methode zum löschen bestimmter logs
    static func deleteLog(_ session: Int){
        if logging{
            print("not deleting anything, active logging at the moment")
            return
        }
        for i in 0 ..< defaults.integer(forKey: String(session)+"-index")+1{
            defaults.removeObject(forKey: String(session)+"-"+String(i))
        }
        defaults.removeObject(forKey: String(session)+"-index")
    }
    
    static func deleteLogs(){
        if logging{
            print("not deleting anything, active logging at the moment")
            return
        }
        for i in 1 ..< defaults.integer(forKey: "Session")+1 {
            deleteLog(i)
        }
        defaults.set(0, forKey: "Session")
    }
}
