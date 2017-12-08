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
    
    override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return .slide
    }
    
    override var prefersStatusBarHidden : Bool {
        return statusBarHidden
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dragger = TableViewDragger(tableView: tableView)
        dragger.dataSource = self
        dragger.delegate = self
        dragger.alphaForCell = 0.7
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension DemoViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoTableViewCell", for: indexPath)
        if let demoCell = cell as? DemoTableViewCell {
            demoCell.demoImageView.image = UIImage(named: imageNames[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let image = UIImage(named: imageNames[indexPath.row]) {
            return image.size.height + 40
        }
        
        return 44
    }
}

extension DemoViewController: TableViewDraggerDataSource, TableViewDraggerDelegate {
    func dragger(_ dragger: TableViewDragger, moveDraggingAt indexPath: IndexPath, newIndexPath: IndexPath) -> Bool {
        let iamgeName = imageNames[indexPath.row]
        imageNames.remove(at: indexPath.row)
        imageNames.insert(iamgeName, at: newIndexPath.row)

        tableView.moveRow(at: indexPath, to: newIndexPath)

        return true
    }
    
    func dragger(_ dragger: TableViewDragger, willBeginDraggingAt indexPath: IndexPath) {
        if let tableView = dragger.tableView {
            let scale = min(max(tableView.bounds.height / tableView.contentSize.height, 0.4), 1)
            dragger.scrollVelocity = scale
            
            tableViewHeightConstraint.constant = (tableView.bounds.height) / scale - tableView.bounds.height
            
            UIView.animate(withDuration: 0.3) {
                self.statusBarHidden = true
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                
                if let tabBarHeight = self.tabBarController?.tabBar.bounds.height {
                    self.tabBarController?.tabBar.frame.origin.y += tabBarHeight
                }
                
                tableView.transform = CGAffineTransform(scaleX: scale, y: scale)
                self.view.layoutIfNeeded()
            } 
        }
    }
    
    func dragger(_ dragger: TableViewDragger, willEndDraggingAt indexPath: IndexPath) {
        tableViewHeightConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3) {
            self.statusBarHidden = false
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            
            if let tabBarHeight = self.tabBarController?.tabBar.bounds.height {
                self.tabBarController?.tabBar.frame.origin.y -= tabBarHeight
            }
            
            if let tableView = dragger.tableView {
                tableView.transform = CGAffineTransform.identity
                self.view.layoutIfNeeded()
                tableView.scrollToRow(at: indexPath, at: .top, animated: false)
            }
        }
    }
}
