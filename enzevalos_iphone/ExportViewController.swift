//
//  ExportViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 04.10.17.
//  Copyright © 2018 fu-berlin.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

class ExportViewController: UITableViewController {
    var alreadySent = false
    var sentToAddress = (UserManager.loadUserValue(Attribute.userAddr) as! String)
    var passcode = ""

    override func viewWillDisappear(_ animated: Bool) {
//        Logger.queue.async(flags: .barrier) {
        Logger.log(exportKeyViewClose: 2)
//        }
        super.viewWillDisappear(animated)
    }

    @IBAction func buttonTouched(_ sender: Any) {

//        Logger.queue.async(flags: .barrier) {
        Logger.log(exportKeyViewButton: !alreadySent)
//        }

        let handler = DataHandler.handler
        let ids = handler.findSecretKeys()
        if ids.count > 0 {
            let id = ids[0]
            let pgp = SwiftPGP()
            if let keyId = id.keyID {
                if alreadySent {
                    if let message = pgp.exportKey(id: keyId, isSecretkey: true, autocrypt: true, newPasscode: true) {
                        passcode = pgp.loadExportPasscode(id: keyId)!
                        let mailHandler = AppDelegate.getAppDelegate().mailHandler
                        mailHandler.sendSecretKey(key: message, passcode: passcode, callback: mailSend)
                    }
                } else {
                    if let message = pgp.exportKey(id: keyId, isSecretkey: true, autocrypt: true, newPasscode: false) {
                        passcode = pgp.loadExportPasscode(id: keyId)!
                        let mailHandler = AppDelegate.getAppDelegate().mailHandler
                        mailHandler.sendSecretKey(key: message, passcode: passcode, callback: mailSend)
                    }
                    alreadySent = true
                }
            }
        }
        else {
            // TODO: Error NO SECRET KEY!
        }
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

        let handler = DataHandler.handler
        let ids = handler.findSecretKeys()
        if ids.count > 0 {
            let id = ids[0]
            let pgp = SwiftPGP()
            if let keyId = id.keyID {
                passcode = pgp.loadExportPasscode(id: keyId) ?? ""
                alreadySent = passcode != ""
            }
        }


//        Logger.queue.async(flags: .barrier) {
        Logger.log(exportKeyViewOpen: 2)
//        }
    }

    func mailSend(_ error: Error?) {
        if (error != nil) {
            NSLog("Error sending email: \(String(describing: error))")
            AppDelegate.getAppDelegate().showMessage("An error occured", completion: nil)
        } else {
            NSLog("Send successful!")
        }
    }

}
