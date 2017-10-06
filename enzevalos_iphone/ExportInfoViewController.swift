//
//  ExportInfoViewController.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 04.10.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class ExportInfoViewController: UITableViewController {
    //TODO: maybe change url; create website!
    let url = "www.enzevalos.de/other"
    
    @IBAction func websiteButtonTouch(_ sender: Any) {
        UIApplication.shared.openURL(URL(string: "https://"+url)!)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 500
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        navigationItem.setRightBarButton(navigationItem.rightBarButtonItem, animated: false)
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("Next", comment: "next step")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExportInfoCell") as! ExportInfoCell
        cell.infoTextLabel.text = NSLocalizedString("ExportInfoViewText", comment: <#T##String#>)
        let qrCodeImage = QRCode.generate(input: "https://"+url)
        
        let scaleX = cell.qrCode.frame.size.width / qrCodeImage.extent.size.width
        let scaleY = cell.qrCode.frame.size.height / qrCodeImage.extent.size.height
        cell.qrCode.image = UIImage.init(ciImage: qrCodeImage.applying(CGAffineTransform(scaleX: scaleX, y: scaleY)))
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
}
