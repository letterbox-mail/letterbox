//
//  ViewController.swift
//  gamification
//
//  Created by Moritz on 22.06.17.
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


/**
 Struct containing all Values necessary for modifying the Badge size
 */
struct BadgeCaseSizes {
    let BadgeSizePercent : CGFloat = 0.6
    let BadgeCaseHorizontalSpacePercent : CGFloat = 0.4
    let BadgeCaseVerticalSpace : CGFloat = 20.0
}




class BadgeCase: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    // MARK:- Variables
    let size = BadgeCaseSizes.init()

    var selected : Badges?


    // MARK:- UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = NSLocalizedString("Badge Case", comment:"Badge Case Navigation Title" )
        if selected != nil {
            self.badgeSelected()
        }
        let badges = GamificationData.sharedInstance.badges
//        Logger.queue.async(flags: .barrier) {
            Logger.log(badgeCaseViewOpen: badges)
//        }
    }



    // MARK:- UICollectionViewDelegate

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return GamificationData.sharedInstance.badges.count / 2 + GamificationData.sharedInstance.badges.count % 2
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (section + 1) * 2 < GamificationData.sharedInstance.badges.count {
            return 2
        } else {
            return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath) as! BadgeCaseCollectionViewCell
        let index = indexPath.row + indexPath.section * 2

        if index > GamificationData.sharedInstance.badges.count { return cell} // Für den fall einer Ungraden anzahl an Badges
        cell.badgeImageView.image = GamificationData.sharedInstance.badges[index].badgeImage()
        cell.badgeName.text = GamificationData.sharedInstance.badges[index].displayName

        return cell
    }



    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {


        let frame = collectionView.frame.width
        let width = frame * size.BadgeSizePercent / 2 // 2 colums of Badges
        return CGSize(width: width * 1.15, height: width * 1.15 )

    }


    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row + indexPath.section * 2

        self.selected = GamificationData.sharedInstance.badges[index]

        self.badgeSelected()



    }


    fileprivate func badgeSelected(){
        guard let selectedBadge = self.selected else {
            let alert = UIAlertController(title: NSLocalizedString("Warning", comment:"warning info header" ), message: NSLocalizedString("Selected Badge not found.", comment:"error message" ), preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)

            return
        }


        switch selectedBadge.segueName {
        case .LinearBadge:
            self.performSegue(withIdentifier: "linearView", sender: self)
            break

        case .inviteFriend:
            self.performSegue(withIdentifier: "inviteFriend", sender: self)
            break
        case .None:
            let alert = UIAlertController(title: NSLocalizedString("Warning", comment:"warning info header" ), message: NSLocalizedString("Segue 'None' not allowed. Check GamificationData and Insert correct Segue", comment:"error message" ), preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            break
        }

    }

    // MARK:- UICollectionViewFlowLayout

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let frame = collectionView.frame.width
        let width = frame * size.BadgeCaseHorizontalSpacePercent / 4 // 4 spacers, (colum left & right each)
        //Spaltenabstandt
        return width
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        // not needed, inset for section takes care of linespacing
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // Abstand zum Rand
        let frame = collectionView.frame.width
        let width = frame * size.BadgeCaseHorizontalSpacePercent / 4


       return UIEdgeInsets.init(top: 10, left: width, bottom: size.BadgeCaseVerticalSpace , right: width)
    }

    // MARK:- Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        if identifier == "linearView" {
            guard let source = segue.source as? BadgeCase else {
                return
            }
            guard let destination = segue.destination as? LinearBadgeViewController else {
                return
            }
            destination.superBadge = source.selected

        }

        if identifier == "inviteFriend" {
            guard let source = segue.source as? BadgeCase else {
                return
            }
            guard let destination = segue.destination as? InviteFriendViewController else {
                return
            }
            destination.superBadge = source.selected

        }
        self.selected = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        let badges = GamificationData.sharedInstance.badges
//        Logger.queue.async(flags: .barrier) {
            Logger.log(badgeCaseViewClose: badges)
//        }
        super.viewWillDisappear(animated)
    }

}

