//
//  InviteFriendViewController.swift
//  enzevalos_iphone
//
//  Created by admin on 24.06.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit
import Contacts

/**
 Displayes Subbadges/Achievments in a linear Fashion (Top to Down) with a Connecting Line

 Additionally Displays a Contact Chooser to Invite selected Contact

 */
class InviteFriendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    // MARK:- Variables
    var superBadge : Badges?
    var subBadges : [Badges] = []
    var contacts: [EnzevalosContact] = [EnzevalosContact]()

    var selectedContact : EnzevalosContact?

    @IBOutlet weak var inviteFriendLabel: UILabel!

    @IBOutlet weak var inviteFriendButton: UIButton!

    @IBOutlet weak var contactTableView: UITableView!

    // MARK:- UIViewController

    override func viewDidLoad() {
        contacts = [EnzevalosContact]()
        let localcontacts = DataHandler.handler.getContacts()
        for element in localcontacts {
            if !element.hasKey{
                contacts.append(element)
            }
        }


        guard let badge = superBadge else {
            subBadges = [Badges]()

            super.viewDidLoad()
            return
        }
        subBadges = GamificationData.sharedInstance.subBadgesforBadge(badge: badge.type)

        super.viewDidLoad()
    }

    // MARK:- TableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView.tag == 0 { // tag 0 = badge Table View, tag 2 = Contacts
            return 2
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 0 { // tag 0 = badge Table View, tag 2 = Contacts
            if section == 0 {
                return 1
            } else {
                let count = subBadges.count * 2 - 1
                if count < 0 {return 0}
                return count
            }
        } else {
            return self.contacts.count

        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 0 { // tag 0 = badge Table View, tag 2 = Contacts
            return self.badgeTableViewGetCell(tableView: tableView, indexPath: indexPath)
        } else {
            return self.contactTableViewGetCell(tableView: tableView, indexPath: indexPath)
        }
    }


    /**
     Provides Cell for SubBadgeViewController
     */
    func badgeTableViewGetCell(tableView : UITableView, indexPath : IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "subBadgeHeader") as! SubBadgeHeaderTableViewCell

            cell.badgeImage.image = self.superBadge!.badgeImage()
            cell.heaerLabel.text = self.superBadge!.displayName

            return cell
        }

        if indexPath.row % 2 == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "subBadgeCell") as! SubBadgeTableViewCell
            let index = indexPath.row / 2


            cell.badgeText.text = subBadges[index].displayName
            cell.badgeImage.image = subBadges[index].badgeImage()
            if subBadges[index].isAchieved() {
                cell.lines.pathColor = UIColor.badgeGreen()
            }
            if subBadges.count == 1 {
                //cell.lines.pathColor = UIColor.clear
                cell.lines.drawTop = .None
            } else if index == subBadges.count - 1 {
                cell.lines.drawTop = .Up
            } else if indexPath.row > 0 {
                cell.lines.drawTop = .Both
            }
            // cell.lines.setNeedsDisplay()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "arrowCell") as! ArrowTableViewCell
            let index = indexPath.row / 2
            if subBadges[index].isAchieved() {
                cell.arrow.pathColor = UIColor.badgeGreen()
            }
            return cell
        }

    }
    /**
    Provides Cell for Contact Table View
     */
    func contactTableViewGetCell(tableView : UITableView, indexPath : IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()

        cell.textLabel?.text = "\( self.contacts[indexPath.row].name )"
        if self.contacts[indexPath.row].hasKey {
            cell.isUserInteractionEnabled = false
            cell.textLabel?.textColor = UIColor.green
        }
        return cell
    }

    // MARK:- TableViewDelegate

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let view = UIView.init(frame: CGRect(x: 0, y: 0, width: 10, height: 20)   )
            return view
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView.tag == 0 { // tag 0 = badge Table View, tag 2 = Contacts
            let view = self.tableView(tableView, viewForHeaderInSection: section)

            if view != nil {
                return view!.frame.height
            } else {
                return 0
            }
        } else {
            return 0
        }

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 0 { // tag 0 = badge Table View, tag 2 = Contacts
            if indexPath.section == 0 {
                return 70
            }
            if indexPath.row % 2 == 0 {
                return 60 // adjust Storyboard if changed
            } else {
                return 20
            }
        } else {
            return 20
        }
    }



    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if tableView.tag == 0 { // tag 0 = badge Table View, tag 2 = Contacts
            tableView.deselectRow(at: indexPath, animated: false)
        } else {
            self.selectedContact = self.contacts[indexPath.row]
        }
    }

    
    @IBAction func invitePressed(_ sender: Any) {
        
        if self.selectedContact != nil {
            self.performSegue(withIdentifier: "send", sender: self)
        } else {
            let alert = UIAlertController(title: NSLocalizedString("Information", comment: "Information title in Alert view") , message: NSLocalizedString("Please select contact", comment: "information message in alert view"), preferredStyle: .alert)
            let ok = UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok button"), style: .default , handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    
    
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "send" {
            let navigationController = segue.destination as? UINavigationController
            if let controller = navigationController?.topViewController as? SendViewController, self.selectedContact != nil {
                let sendTo = selectedContact!.getMailAddresses()

                let body = String(format: NSLocalizedString("inviteText", comment: "Body for the invitation mail"), StudySettings.studyID)
                let time = DateFormatter.init()
                time.dateStyle = .short
                time.timeStyle = .short
                time.locale = Locale.current


            
                let subject = NSLocalizedString("inviteSubject", comment: "Subject for the invitation mail")

                let answerMail = EphemeralMail(to: NSSet.init(array: sendTo), cc: [], bcc: [], date: Date(), subject: subject, body: body, uid: 0, predecessor: nil)

                controller.prefilledMail = answerMail
            }
        }
     }

    
    
}
