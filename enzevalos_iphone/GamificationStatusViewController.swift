//
//  GamificationStatusViewController.swift
//  enzevalos_iphone
//
//  Created by admin on 14.07.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class GamificationStatusViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    //TODO: kein rand, schrift anpassen. Farbe anpassen
// design pattern

    @IBOutlet weak var secureContactsProgress: UIProgressView!
    @IBOutlet weak var secureCommunicationProgress: UIProgressView!

    @IBOutlet weak var secureContactsPercent: UILabel!

    @IBOutlet weak var secureCommunicationPercent: UILabel!

    

    @IBOutlet weak var lastAchievedBadgeOne: UIButton!
    @IBOutlet weak var lastAchievedBadgeTwo: UIButton!
    @IBOutlet weak var lastAchievedBadgeThree: UIButton!

    @IBOutlet weak var lastAchievedLabelOne: UILabel!
    @IBOutlet weak var lastAchievedLabelTwo: UILabel!
    @IBOutlet weak var lastAchievedLabelThree: UILabel!


    @IBOutlet weak var openBadgeCaseButton: UIButton!

    @IBOutlet weak var tableView: UITableView!


    
    var selected : Badges?

    let lastAchieved : [Badges] = GamificationData.sharedInstance.get3LastAchieved()


    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = NSLocalizedString("Me", comment:"Navigation Title" )




        // set up Buttons
        if (lastAchieved.count > 0 ) {
            let badge = lastAchieved[0]
            self.lastAchievedBadgeOne.setImage(badge.badgeImage(), for: UIControlState.normal)
            self.lastAchievedLabelOne.text = badge.displayName
            self.lastAchievedLabelOne.isHidden = false
            self.lastAchievedBadgeOne.isHidden = false
        }
        if (lastAchieved.count > 1 ) {
            let badge = lastAchieved[1]
            self.lastAchievedBadgeTwo.setImage(badge.badgeImage(), for: UIControlState.normal)
            self.lastAchievedLabelTwo.text = badge.displayName
            self.lastAchievedLabelTwo.isHidden = false
            self.lastAchievedBadgeTwo.isHidden = false
        }
        if (lastAchieved.count > 2 ) {
            let badge = lastAchieved[2]
            self.lastAchievedBadgeThree.setImage(badge.badgeImage(), for: UIControlState.normal)
            self.lastAchievedLabelThree.text = badge.displayName
            self.lastAchievedLabelThree.isHidden = false
            self.lastAchievedBadgeThree.isHidden = false
        }


        // set up Progress Bars
        let (contact,mail) = GamificationData.sharedInstance.getSecureProgress()

        self.secureContactsProgress.progress = contact
        self.secureContactsPercent.text = "\(Int(contact * 100)) %"//"\(contact.rounded(FloatingPointRoundingRule.down) ) %"

        self.secureCommunicationProgress.progress = mail
        self.secureCommunicationPercent.text = "\(Int(mail * 100)) %"



    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }



    @IBAction func lastAchievedPressed(_ sender: UIButton) {

        self.selected = lastAchieved[sender.tag]

        self.performSegue(withIdentifier: "badge", sender: self)


    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "userdataCell") as! UserNameGamificationTableViewCell


            // set user data
            let username = UserManager.loadUserValue( Attribute.accountname ) as! String
            let usermail = UserManager.loadUserValue( Attribute.userAddr ) as! String

            cell.userName.text = username
            cell.mailLabel.text = "(\(usermail))"


            return cell

        }

        if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "accountInfoCell") 


            return cell!

        }


        return UITableViewCell() // dummy return, should never be reached
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "userdataCell") as! UserNameGamificationTableViewCell


            // set user data
            let username = UserManager.loadUserValue( Attribute.accountname ) as! String
            let usermail = UserManager.loadUserValue( Attribute.userAddr ) as! String

            cell.userName.text = username
            cell.mailLabel.text = "(\(usermail))"


            return cell.frame.height

        } else {
         //   let cell = tableView.dequeueReusableCell(withIdentifier: "accountInfoCell")
            
            
            return 40
            
        }

    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

    }





    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            print("Identifier Failure")
            return
        }
        guard let badge = self.selected else {
            print("Non achieved Selected, proceeding with no Selection")
            return
        }
        if identifier == "badge" {
//            guard let source = segue.source as? GamificationStatusViewController else {
//                print("GamificationStatusViewController Failure")
//                return
//            }
            guard let destination = segue.destination as? BadgeCase else {
                print("BadgeCase Failure (in: gamificationStatusView)")
                return
            }
            destination.selected = badge

        }

    }


}