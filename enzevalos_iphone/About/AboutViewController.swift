//
//  AboutViewController.swift
//  enzevalos_iphone
//
//  Created by Joscha on 22.12.17.
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

import Foundation

class AboutViewController: UIViewController {
    var textDelegate: AboutTextDelegate?
    @IBOutlet weak var aboutText: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        textDelegate = AboutTextDelegate()
        textDelegate?.callback = newMailCallback
        aboutText.delegate = textDelegate
    }

    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }

    func newMailCallback(Address: String) {
        performSegue(withIdentifier: "newMail", sender: Address)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newMail" {
            let navigationController = segue.destination as? UINavigationController
            if let controller = navigationController?.topViewController as? SendViewController {

                let answerTo = sender as? String ?? ""

                let answerMail = EphemeralMail(to: [answerTo])

                controller.prefilledMail = answerMail
            }
        }
    }
}

class AboutTextDelegate: NSObject, UITextViewDelegate {
    var callback: ((String) -> ())?

    @available(iOS, deprecated: 10.0)
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL.scheme == "mailto" {
            callback?(URL.absoluteString.replacingOccurrences(of: "mailto:", with: ""))
            return false
        }
        return true
    }

    @available(iOS 10.0, *)
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if url.scheme == "mailto" {
            callback?(url.absoluteString.replacingOccurrences(of: "mailto:", with: ""))
            return false
        }
        return true
    }
}

