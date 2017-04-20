//
//  FrequentCollectionViewLayout.swift
//  enzevalos_iphone
//
//  Created by jakobsbode on 09.03.17.
//  Copyright © 2017 fu-berlin. All rights reserved.
//

import UIKit

class FrequentCollectionViewLayout : UICollectionViewFlowLayout {
    override init() {
        super.init()
        //self.scrollDirection = UICollectionViewScrollDirection.horizontal
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//self.scrollDirection = UICollectionViewScrollDirection.horizontal
        self.invalidateLayout()
    }
    
    override var collectionViewContentSize: CGSize {
        get{
            if let cv = self.collectionView {
                if let number = self.collectionView?.dataSource?.collectionView(cv, numberOfItemsInSection: 0) {
                    print("layout: \(number)")
                    return CGSize(width: 90*number, height: 90)
                }
            }
            return CGSize(width: 0, height: 90)
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attr = UICollectionViewLayoutAttributes.init(forCellWith: IndexPath.init(row: 0, section: 0))
        return [attr]
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes.init(forCellWith: indexPath)
        attr.frame = CGRect.init(x: 0, y: 0, width: 90, height: 90)
        if indexPath.row == 1 {
            attr.frame = CGRect.init(x: 90, y: 0, width: 90, height: 90)
        }
        return attr
    }
}

extension UICollectionViewFlowLayout {
    func test() {
        
    }
}
