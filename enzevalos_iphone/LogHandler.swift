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
    
    private static var defaults = NSUserDefaults.init()
    private(set) static var logging = false
    private static var date = NSDate.init()
    static var session : Int = 0
    
    static func newLog(){
        logging = true
        session = defaults.integerForKey("Session")
        if session == 0{
            session = 1
        }
        else {
            session += 1
        }
        defaults.setInteger(session, forKey: "Session")
        defaults.setInteger(0, forKey: String(session)+"-index")
        defaults.setObject("time,caller,interaction,point,comment"/*"time,caller,interaction,point,debugDescription,comment"*/, forKey: String(session)+"-0")
        date = NSDate.init()
        defaults.setObject(date.description, forKey: String(session)+"-date")
        print("Logging Session: ",session)
        print(date.description)
    }
    
    static func stopLogging(){
        logging = false
    }
    
    //TODO: escaping in comment and debugDescription
    static func doLog(caller: String?, interaction: String, point: CGPoint, /*debugDescription: String,*/ comment : String){
        var entry = ""
        let now = NSDate.init()
        //Zeit holen
        entry.appendContentsOf(String(now.timeIntervalSinceDate(date)))
        entry.appendContentsOf(",")
        //caller identifizieren
        if caller != nil{
            entry.appendContentsOf(caller!)
        }
        entry.appendContentsOf(",")
        //interaction bestimmen
        entry.appendContentsOf(interaction)
        entry.appendContentsOf(",")
        //Punkt anbinden
        entry.appendContentsOf(String(point))
        entry.appendContentsOf(",")
        //debugDescription anhängen
        //entry.appendContentsOf(debugDescription)
        //entry.appendContentsOf(",")
        //text anbinden
        entry.appendContentsOf(comment)
        //in nsuserdefaults speichern
        var index = defaults.integerForKey(String(session)+"-index")
        index += 1
        defaults.setInteger(index, forKey: String(session)+"-index")
        defaults.setObject(entry, forKey: String(session)+"-"+String(index))
    }
    
    //methode zum auslesen eines logs
    static func printLog(session : Int){
        print()
        print("--------------------LOG OUTPUT--------------------")
        print("LoggingSession ",session)
        print(defaults.objectForKey(String(session)+"-date"))
        print()
        for var i in 0 ..< defaults.integerForKey(String(session)+"-index")+1{
            if let entry = defaults.objectForKey(String(session)+"-"+String(i)) {
                    print(String(entry))
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
        for var i in 1 ..< defaults.integerForKey("Session")+1 {
            printLog(i)
        }
    }
    
    static func getLog(session : Int) -> String{
        var log = "\n--------------------LOG OUTPUT--------------------\nLoggingSession "+String(session)+"\n"+String(defaults.objectForKey(String(session)+"-date"))+"\n\n"
        
        for var i in 0 ..< defaults.integerForKey(String(session)+"-index")+1{
            if let entry = defaults.objectForKey(String(session)+"-"+String(i)) {
                log.appendContentsOf(String(entry)+"\n")
            }
            else {
                log.appendContentsOf(",,,,\n")//log.appendContentsOf(",,,,,\n")
            }
        }
        log.appendContentsOf("\n--------------------------------------------------\n\n")
        
        return log
    }
    
    static func getLogs() -> String {
        var logs = ""
        for var i in 1 ..< defaults.integerForKey("Session")+1 {
            logs.appendContentsOf(getLog(i))
        }
        return logs
    }
    
    //methode zum löschen bestimmter logs
    static func deleteLog(session: Int){
        if logging{
            print("not deleting anything, active logging at the moment")
            return
        }
        for var i in 0 ..< defaults.integerForKey(String(session)+"-index")+1{
            defaults.removeObjectForKey(String(session)+"-"+String(i))
        }
        defaults.removeObjectForKey(String(session)+"-index")
    }
    
    static func deleteLogs(){
        if logging{
            print("not deleting anything, active logging at the moment")
            return
        }
        for var i in 1 ..< defaults.integerForKey("Session")+1 {
            deleteLog(i)
        }
        defaults.setInteger(0, forKey: "Session")
    }
}
