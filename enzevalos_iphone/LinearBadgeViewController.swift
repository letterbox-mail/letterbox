//
//  LinearBadgeViewController.swift
//  enzevalos_iphone
//
//  Created by Moritz on 25.06.17.
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
    Displayes Subbadges/Achievments in a linear Fashion (Top to Down) with a Connecting Line
 */
class LinearBadgeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK:- Variables
    var superBadge : Badges?
    var subBadges : [Badges] = []

    // MARK:- UIViewController

    override func viewDidLoad() {
        guard let badge = superBadge else {
            subBadges = [Badges]()
            super.viewDidLoad()
            return
        }
        subBadges = GamificationData.sharedInstance.subBadgesforBadge(badge: badge.type)
        super.viewDidLoad()
    }


    // MARK:- TableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {

        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            let count = subBadges.count * 2 - 1
            if count < 0 {return 0}
            return count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "subBadgeHeader") as! SubBadgeHeaderTableViewCell

            cell.badgeImage.image = self.superBadge!.badgeImage()
            cell.heaerLabel.text = self.superBadge!.displayName

            return cell
        }

        if indexPath.row % 2 == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "subBadgeCell") as! SubBadgeTableViewCell
            let index = indexPath.row / 2


            cell.badgeText.text = subBadges[index].displayName
            cell.badgeImage.image = subBadges[index].badgeImage()
            if subBadges[index].isAchieved() {
                cell.lines.pathColor = UIColor.badgeGreen()
            }
            if subBadges.count == 1 {
                //cell.lines.pathColor = UIColor.clear
                cell.lines.drawTop = .None
            } else if index == subBadges.count - 1 {
                cell.lines.drawTop = .Up
            } else if indexPath.row > 0 {
                cell.lines.drawTop = .Both
            }
           // cell.lines.setNeedsDisplay()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "arrowCell") as! ArrowTableViewCell
             let index = indexPath.row / 2
            if subBadges[index].isAchieved() {
                cell.arrow.pathColor = UIColor.badgeGreen()
            }

            return cell
        }
    }
    // MARK:- TableViewDelegate

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let view = UIView.init(frame: CGRect(x: 0, y: 0, width: 10, height: 20)   )
            return view
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let view = self.tableView(tableView, viewForHeaderInSection: section)

        if view != nil {
            return view!.frame.height
        } else {
            return 0
        }


    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 70
        }
        if indexPath.row % 2 == 0 {
            return 60 // adjust Storyboard if changed
        } else {
            return 20
        }
    }


    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }

}
