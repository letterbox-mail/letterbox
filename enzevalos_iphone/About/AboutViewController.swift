//
//  AboutViewController.swift
//  enzevalos_iphone
//
//  Created by Joscha on 22.12.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
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

    func close() {
        self.dismiss(animated: true, completion: nil)
    }

    func newMailCallback(Address: String) {
        performSegue(withIdentifier: "newMail", sender: Address)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newMail" {
            let navigationController = segue.destination as? UINavigationController
            if let controller = navigationController?.topViewController as? SendViewController {

                let answerTo = sender as? String ?? "" // TODO: Convert String into MailAddress(?)

                let answerMail = EphemeralMail(to: NSSet.init(array: [answerTo]), cc: NSSet.init(array: []), bcc: [], date: Date(), subject: "", body: "", uid: 0, predecessor: nil) // TODO: are these the best values?

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

