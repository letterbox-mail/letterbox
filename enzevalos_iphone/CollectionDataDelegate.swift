//
//  CollectionDataDelegate.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 16.09.16.
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

import UIKit

class CollectionDataDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {

    var collectionView: UICollectionView?

    var suggestionFunc: (([String]) -> [(UIImage, String, String, UIImage?, UIColor)])
    //[bereits eingetragene emailadresse] -> [(Kontaktbild, Name, Emailadresse, emailTypeImage)]
    var alreadyInserted: [String] = []
    var suggestion: [(UIImage, String, String, UIImage?, UIColor)] = []
    var insertCallback: (String, String) -> Void = { (name: String, address: String) -> Void in return }


    //used in suggestionFunc
    static let maxFrequent = 10

    init(suggestionFunc: @escaping ([String]) -> [(UIImage, String, String, UIImage?, UIColor)], insertCallback: @escaping (String, String) -> Void) {
        self.suggestionFunc = suggestionFunc
        self.insertCallback = insertCallback
        super.init()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        suggestion = suggestionFunc(alreadyInserted)
        return suggestion.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "frequent", for: indexPath) as! FrequentCell
        cell.autoresizingMask = UIViewAutoresizing.flexibleHeight
        cell.clipsToBounds = true
        let index = indexPath.row
        cell.img.layer.cornerRadius = cell.img.frame.height / 2
        cell.img.clipsToBounds = true
        cell.img.image = suggestion[index].0
        cell.name.text = suggestion[index].1
        cell.address = suggestion[index].2
        if suggestion[index].3 != nil {
            cell.type.image = suggestion[index].3
            cell.drawBackgroud(suggestion[index].4)
        }
        else {
            cell.type.image = UIImage()
            cell.background.image = UIImage()
        }
        return cell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tuple = suggestion[indexPath.row]
        insertCallback(tuple.1, tuple.2)
    }

}
