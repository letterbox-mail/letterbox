//
//  TableViewDataDelegate.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 01.09.16.
//  //  This program is free software: you can redistribute it and/or modify
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


class TableViewDataDelegate: NSObject, UITableViewDelegate, UITableViewDataSource {

    var contacts: [String] = []
    var addresses: [String] = []
    var pictures: [UIImage?] = []
    var insertCallback: (String, String) -> Void = { (name: String, address: String) -> Void in return }

    init(insertCallback: @escaping (String, String) -> Void) {
        self.insertCallback = insertCallback
        super.init()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contacts") as! ContactCell
        cell.name.text = contacts[indexPath.row]
        cell.address.text = addresses[indexPath.row]
        cell.img.layer.cornerRadius = cell.img.frame.height / 2
        cell.img.clipsToBounds = true
        cell.img.image = pictures[indexPath.row]
        if let img = pictures[indexPath.row] {
            cell.img.image = img
        }

        if !DataHandler.handler.hasKey(adr: cell.address.text!) {
            cell.name.textColor! = UIColor.orange
            cell.address.textColor! = UIColor.orange
        }
        else {
            cell.name.textColor! = UIColor.black
            cell.address.textColor! = UIColor.black
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.insertCallback(contacts[indexPath.row], addresses[indexPath.row])
    }

}
