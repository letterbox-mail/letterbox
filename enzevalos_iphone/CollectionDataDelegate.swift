//
//  CollectionDataDelegate.swift
//  mail_dynamic_icon_001
//
//  Created by jakobsbode on 16.09.16.
//  Copyright © 2016 jakobsbode. All rights reserved.
//

import UIKit

class CollectionDataDelegate : NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var collectionView: UICollectionView?
    
    var suggestionFunc : (([String]) -> [(UIImage, String, String, UIImage?, UIColor)])
                    //[bereits eingetragene emailadresse] -> [(Kontaktbild, Name, Emailadresse, emailTypeImage)]
    var alreadyInserted : [String] = [] {
        didSet {
            if let collectionView = self.collectionView {
                let diff = collectionView.numberOfItems(inSection: 0) - self.oldCount
                /*if diff > 0 {
                    for i in 0..<diff {
                        collectionView.insertItems(at: [IndexPath.init(row: collectionView.numberOfItems(inSection: 0)-diff+i, section: 0)])
                    }
                }*/
                /*if diff < 0 {
                    for i in 0 ..< -diff {
                        collectionView.deleteItems(at: [IndexPath.init(row: collectionView.numberOfItems(inSection: 0), section: 0)])
                    }
                }*/
                oldCount = collectionView.numberOfItems(inSection: 0)
            }
        }
    }
    private var oldCount = 10
    var insertCallback : (String, String) -> Void = {(name : String, address : String) -> Void in return}
    
    private var reloading = false
    
    //used in suggestionFunc
    static let maxFrequent = 10
    
    init(suggestionFunc: @escaping ([String]) -> [(UIImage, String, String, UIImage?, UIColor)], insertCallback : @escaping (String, String) -> Void, collectionView: UICollectionView?){
        self.suggestionFunc = suggestionFunc
        self.insertCallback = insertCallback
        self.collectionView = collectionView
        super.init()
        if let collectionView = self.collectionView {
            oldCount = self.collectionView(collectionView, numberOfItemsInSection: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(suggestionFunc(alreadyInserted).count)
        print("section: ",section)
        var retVal = suggestionFunc(alreadyInserted).count
        /*if reloading {
            retVal += 1
        }*/
        return retVal
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print(indexPath.row, indexPath.description)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "frequent", for: indexPath) as! FrequentCell
        cell.autoresizingMask = UIViewAutoresizing.flexibleHeight
        //cell.translatesAutoresizingMaskIntoConstraints = false
        cell.frame = CGRect.init(x: 90*indexPath.row, y: 0, width: 90, height: 90)
        cell.clipsToBounds = true
        cell.bounds = CGRect.init(x: 90*indexPath.row, y: 0, width: 90, height: 90)
        cell.contentView.frame = CGRect.init(x: 90*indexPath.row, y: 0, width: 90, height: 90)
        let index = indexPath.row
        cell.img.layer.cornerRadius = cell.img.frame.height/2
        cell.img.clipsToBounds = true
        cell.img.image = suggestionFunc(alreadyInserted)[index].0
        cell.name.text = suggestionFunc(alreadyInserted)[index].1
        cell.address = suggestionFunc(alreadyInserted)[index].2
        if suggestionFunc(alreadyInserted)[index].3 != nil {
            cell.type.image = suggestionFunc(alreadyInserted)[index].3
            cell.drawBackgroud(suggestionFunc(alreadyInserted)[index].4)
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
        let tuple = suggestionFunc(alreadyInserted)[indexPath.row]
        if !reloading {
            insertCallback(tuple.1, tuple.2)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("display \(indexPath)")
    }
    
    func reloadBugfix(collectionView: UICollectionView) {
        reloading = true
        //collectionView.insertItems(at: [IndexPath.init(row: 0, section: 0)])
        let loop = self.collectionView(collectionView, numberOfItemsInSection: 0)
        for i in 0..<loop {
            collectionView.selectItem(at: IndexPath.init(row: i, section: 0), animated: true, scrollPosition: UICollectionViewScrollPosition.bottom)
        }
        //collectionView.selectItem(at: IndexPath.init(row: 0, section: 0), animated: true, scrollPosition: UICollectionViewScrollPosition.bottom)
        reloading = false
    }
    
}
