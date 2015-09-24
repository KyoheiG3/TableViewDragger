//
//  DemoViewController.swift
//  TableViewDraggerExample
//
//  Created by Kyohei Ito on 2015/09/25.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import TableViewDragger

class DemoViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    var dragger: TableViewDragger!
    
    var imageNames = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    var statusBarHidden: Bool = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return statusBarHidden
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dragger = TableViewDragger(tableView: tableView)
        dragger.dataSource = self
        dragger.delegate = self
        dragger.cellAlpha = 0.7
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension DemoViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DemoTableViewCell", forIndexPath: indexPath)
        if let demoCell = cell as? DemoTableViewCell {
            demoCell.demoImageView.image = UIImage(named: imageNames[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let image = UIImage(named: imageNames[indexPath.row]) {
            return image.size.height + 40
        }
        
        return 44
    }
}

extension DemoViewController: TableViewDraggerDataSource, TableViewDraggerDelegate {
    func dragger(dragger: TableViewDragger, moveDraggingAtIndexPath indexPath: NSIndexPath, newIndexPath: NSIndexPath) -> Bool {
        swap(&imageNames[indexPath.row], &imageNames[newIndexPath.row])
        
        tableView.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
        
        return true
    }
    
    func dragger(dragger: TableViewDragger, willBeginDraggingAtIndexPath indexPath: NSIndexPath) {
        if let tableView = dragger.tableView {
            let scale = min(max(tableView.bounds.height / tableView.contentSize.height, 0.4), 1)
            dragger.scrollVelocity = scale
            
            tableViewHeightConstraint.constant = (tableView.bounds.height) / scale - tableView.bounds.height
            
            UIView.animateWithDuration(0.3) {
                self.statusBarHidden = true
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                
                if let tabBarHeight = self.tabBarController?.tabBar.bounds.height {
                    self.tabBarController?.tabBar.frame.origin.y += tabBarHeight
                }
                
                tableView.transform = CGAffineTransformMakeScale(scale, scale)
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func dragger(dragger: TableViewDragger, willEndDraggingAtIndexPath indexPath: NSIndexPath) {
        tableViewHeightConstraint.constant = 0
        
        UIView.animateWithDuration(0.30) {
            self.statusBarHidden = false
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            
            if let tabBarHeight = self.tabBarController?.tabBar.bounds.height {
                self.tabBarController?.tabBar.frame.origin.y -= tabBarHeight
            }
            
            if let tableView = dragger.tableView {
                tableView.transform = CGAffineTransformIdentity
                self.view.layoutIfNeeded()
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
            }
        }
    }
}
