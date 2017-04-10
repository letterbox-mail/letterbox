//
//  CollectionDataDelegate.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 16.09.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import UIKit

class CollectionDataDelegate : NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var suggestionFunc : (([String]) -> [(UIImage, String, String, UIImage?, UIColor)])
                    //[bereits eingetragene emailadresse] -> [(Kontaktbild, Name, Emailadresse, emailTypeImage)]
    var alreadyInserted : [String] = []
    var insertCallback : (String, String) -> Void = {(name : String, address : String) -> Void in return}
    
    static let maxFrequent = 10
    
    init(suggestionFunc: @escaping ([String]) -> [(UIImage, String, String, UIImage?, UIColor)], insertCallback : @escaping (String, String) -> Void){
        self.suggestionFunc = suggestionFunc
        self.insertCallback = insertCallback
        super.init()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(suggestionFunc(alreadyInserted).count)
        print("section: ",section)
        return suggestionFunc(alreadyInserted).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print(indexPath.row, indexPath.description)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "frequent", for: indexPath) as! FrequentCell
        cell.img.layer.cornerRadius = cell.img.frame.height/2
        cell.img.clipsToBounds = true
        cell.img.image = suggestionFunc(alreadyInserted)[indexPath.row].0
        cell.name.text = suggestionFunc(alreadyInserted)[indexPath.row].1
        cell.address = suggestionFunc(alreadyInserted)[indexPath.row].2
        if suggestionFunc(alreadyInserted)[indexPath.row].3 != nil {
            cell.type.image = suggestionFunc(alreadyInserted)[indexPath.row].3
            cell.drawBackgroud(suggestionFunc(alreadyInserted)[indexPath.row].4)
        }
        else {
            cell.type.image = UIImage()
            cell.background.image = UIImage()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tuple = suggestionFunc(alreadyInserted)[indexPath.row]
        insertCallback(tuple.1, tuple.2)
    }
}
