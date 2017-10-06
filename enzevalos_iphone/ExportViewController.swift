//
//  ExportViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 04.10.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class ExportViewController: UITableViewController {
    var alreadySent = false
    var sentToAddress = (UserManager.loadUserValue(Attribute.userAddr) as! String)
    var passcode = "1234-1234-1234-5678-5678-5678-9012-9012-9012"
    
    @IBAction func buttonTouched(_ sender: Any) {
        if !alreadySent {
            //TODO: create passcode for AES, export key, send mail
        }
        
        alreadySent = !alreadySent
        //TODO: Save states like alreadySent, secret and address the mail were sent to
        tableView.reloadData()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
        self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if alreadySent {
            return 2
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return 1
        }
        return 0
    }
    
    /*override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return 120
            }
            if indexPath.row == 1 {
                return 44
            }
        }
        return 205
    }*/
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ExportEmailCell") as! ExportEmailCell
                if alreadySent {
                    cell.addressLabel.text = sentToAddress
                    cell.topLabel.text = NSLocalizedString("ExportKeyMailWasSentTopLabel", comment: "")
                    cell.bottomLabel.text = NSLocalizedString("ExportKeyMailWasSentBottomLabel", comment: "")
                }
                else {
                    cell.addressLabel.text = (UserManager.loadUserValue(Attribute.userAddr) as! String)
                    cell.topLabel.text = NSLocalizedString("ExportKeyMailWillBeSentTopLabel", comment: "")
                    cell.bottomLabel.text = NSLocalizedString("ExportKeyMailWillBeSentBottomLabel", comment: "")
                }
                return cell
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ExportSendButtonCell") as! ExportSendButtonCell
                if alreadySent {
                    cell.sendButton.setTitle(NSLocalizedString("DeleteCode", comment: "delete (pass-)code, which was used to symmetrically encrypt the secret key"), for: UIControlState.normal) //geht besser...
                    cell.sendButton.setTitleColor(UIColor.red, for: .normal)
                    //TODO: delete code from keychain
                } else {
                    cell.sendButton.setTitle(NSLocalizedString("Send", comment: "send mail with secret key attached"), for: .normal)
                    cell.sendButton.setTitleColor(cell.tintColor, for: .normal)
                }
                return cell
            }
            
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExportSecretCell") as! ExportSecretCell
        cell.infoTextLabel.text = NSLocalizedString("codeExplanation", comment: "")
        cell.setSecretToLabels(secret: passcode)
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("Done", comment: "")
    }
}
