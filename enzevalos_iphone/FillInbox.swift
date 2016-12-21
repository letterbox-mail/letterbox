//
//  FillInbox.swift
//  readView
//
//  Created by Joscha on 12.09.16.
//  Copyright © 2016 Joscha. All rights reserved.
//

import Foundation
import Contacts

func generateMail() -> [EnzevalosContact] {
    let cons = ["Hans", "Tina", "Anna", "Martin", "Jakob", "Elisabet", "Susi", "Eva", "Joscha"]
    let sur = ["Jürgen", "T.", "Lotte", "Schulzenheimer", "Bode", "Sue", "Koch", "Fuchs", "Lausch"]
    let emails = ["hans@web.de", "tina@mail.com", "anni@hotmail.com", "martin.schulzenheimer@googlemail.com", "jakob.bode@fu-berlin.de", "eli.sue@mail.com", "susi92@gmail.com", "eva.fuchs@fu-berlin.de", "joscha.lausch@fu-berlin.de"]
    let subjects = ["Good seing you!", "Nice meeting you", "Grüße aus Malle", "WTF happend?!", "You need to see this", "Hey!", "Fahrrad", "Umfrage", " ", "Einladung zur Verteidigung meiner Bachelorarbeit", "Had a great time!", "Reiseplanung", "How are you?", "Probleme...", "well...", "Re: (no subject)", "Grüße", "Yosemite Trip", "Paper Submission", "Backpacking through Europe"]
    let lorem = "Lorem ipsum dolor sit amet, consectetur adipisici elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquid ex ea commodi consequat. Quis aute iure reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint obcaecat cupiditat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum." + "\n\n" + "Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat." + "\n\n" + "Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi." + "/n/n" + "Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat."
    
    var contacts: [EnzevalosContact] = []
    
    for c in (0..<cons.count) {
        let con = CNMutableContact()
        con.givenName = cons[c]
        con.familyName = sur[c]
        con.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: emails[c])]
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        
        var mails: [Mail] = []
        
        let encrypted = randBool()
        
        for _ in (0..<arc4random_uniform(3)+1) {
            var date: NSDate?
            repeat {
            let d = "\(10 + arc4random_uniform(22))-0\(arc4random_uniform(9)+1)-201\(arc4random_uniform(7)) \(arc4random_uniform(3))\(arc4random_uniform(10)):\(arc4random_uniform(6))\(arc4random_uniform(10))"
            date = dateFormatter.dateFromString(d)
            } while(date == nil)
            
//            let mail = Mail(sender: emails[c], receivers: ["bob@web.de", emails[Int(arc4random_uniform(UInt32(emails.count)))]], time: date, received: true, subject: subjects[Int(arc4random_uniform(UInt32(subjects.count)))], body: lorem, isEncrypted: encrypted, isVerified: false, trouble: false)
//            mail.isUnread = randBool()
//            
//            mails.append(mail)
        }
        
        contacts.append(EnzevalosContact(contact: con, mails: mails, isSecure: mails[0].isSecure))
    }
    
    return contacts
}

func randBool() -> Bool {
    return arc4random_uniform(2) == 0 ? true: false
}
