//
//  InboxTableViewCell.swift
//  readView
//
//  Created by Joscha on 29.08.16.
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
import Contacts

class InboxTableViewCell: UITableViewCell {
    weak var delegate: InboxCellDelegator?

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var faceView: UIImageView!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var firstSubjectLabel: UILabel!
    @IBOutlet weak var firstMessageLabel: UILabel!
    @IBOutlet weak var firstDateLabel: UILabel!
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondSubjectLabel: UILabel!
    @IBOutlet weak var secondMessageLabel: UILabel!
    @IBOutlet weak var secondDateLabel: UILabel!
    @IBOutlet weak var secondButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var seperator: NSLayoutConstraint!
    @IBOutlet weak var seperator2: NSLayoutConstraint!
    @IBOutlet weak var contactButton: UIButton!

    @IBAction func firstButtonPressed(_ sender: AnyObject) {
        if let delegate = delegate, firstMail != nil {
            firstButton.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
            delegate.callSegueFromCell(firstMail)
        }
    }

    @IBAction func secondButtonPressed(_ sender: AnyObject) {
        if let delegate = delegate, secondMail != nil {
            secondButton.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
            delegate.callSegueFromCell(secondMail)
        }
    }

    @IBAction func moreButtonPressed(_ sender: AnyObject) {
        if let delegate = delegate {
            delegate.callSegueFromCell2(enzContact)
        }
    }

    @IBAction func contactButtonPressed(_ sender: AnyObject) {
        if let delegate = delegate {
            delegate.callSegueToContact(enzContact)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // prevent two buttons being pressed at the same time
        firstButton.isExclusiveTouch = true
        secondButton.isExclusiveTouch = true
        moreButton.isExclusiveTouch = true
        contactButton.isExclusiveTouch = true

        firstButton.backgroundColor = UIColor.clear
        secondButton.backgroundColor = UIColor.clear
        firstButton.addTarget(self, action: .cellTouched, for: [.touchDown, .touchDragEnter])
        firstButton.addTarget(self, action: .clearCell, for: [.touchUpOutside, .touchDragExit, .touchCancel])
        secondButton.addTarget(self, action: .cellTouched, for: [.touchDown, .touchDragEnter])
        secondButton.addTarget(self, action: .clearCell, for: [.touchUpOutside, .touchDragExit, .touchCancel])
        seperator.constant = 1 / UIScreen.main.scale
        seperator2.constant = 1 / UIScreen.main.scale
    }

    var enzContact: KeyRecord? {
        didSet {
            if let con = enzContact {
                let mails = con.inboxMails
                firstMail = mails.first
                if mails.count > 1 {
                    secondMail = mails[1]
                    secondButton.isEnabled = true
                } else {
                    secondDateLabel.text = ""
                    secondSubjectLabel.text = ""
                    secondMessageLabel.text = NSLocalizedString("NoFurtherMessages", comment: "There is only one message from this sender.")
                    secondButton.isEnabled = false
                }
                if con.isSecure {
                    iconView.image = IconsStyleKit.imageOfLetterBG
                } else {
                    iconView.image = IconsStyleKit.imageOfPostcardBG
                }

                var cont: Contact
                if let contact = con.cnContact {
                    cont = contact
                } else {
                    cont = con.ezContact
                }
                nameLabel.text = cont.name
                faceView.image = cont.getImageOrDefault()
                faceView.layer.cornerRadius = faceView.frame.height / 2
                faceView.clipsToBounds = true
            }
        }
    }

    var firstMail: PersistentMail? {
        didSet {
            if let mail = firstMail {
                if !mail.isRead {
                    firstSubjectLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
                } else {
                    firstSubjectLabel.font = UIFont.systemFont(ofSize: 17.0)
                }

                firstSubjectLabel.text = mail.getSubjectWithFlagsString()

                firstMessageLabel.text = mail.shortBodyString

                firstDateLabel.text = mail.timeString
            }
        }
    }

    var secondMail: PersistentMail? {
        didSet {
            if let mail = secondMail {
                if !mail.isRead {
                    secondSubjectLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
                } else {
                    secondSubjectLabel.font = UIFont.systemFont(ofSize: 17.0)
                }

                secondSubjectLabel.text = mail.getSubjectWithFlagsString()

                secondMessageLabel.text = mail.shortBodyString

                secondDateLabel.text = mail.timeString

                moreButton.isEnabled = true
            }
        }
    }

    @objc func cellTouched(_ sender: AnyObject) {
        if let button = sender as? UIButton {
            button.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        }
    }

    @objc func clearCell(_ sender: AnyObject) {
        if let button = sender as? UIButton {
            UIView.animate(withDuration: 0.5, animations: { button.backgroundColor = UIColor.clear })
        }
    }
}

private extension Selector {
    static let cellTouched = #selector(InboxTableViewCell.cellTouched(_:))
    static let clearCell = #selector(InboxTableViewCell.clearCell(_:))
}
