//
//  TableViewController.swift
//  TableViewDraggerExample
//
//  Created by Kyohei Ito on 2017/12/08.
//  Copyright © 2017年 kyohei_ito. All rights reserved.
//

import UIKit
import TableViewDragger

class TableViewController: UITableViewController {

    var dragger: TableViewDragger!
    var items: [[String]] = (0..<10).map { i in (0..<10).map { j in "\(i) - \(j)" } }

    override func viewDidLoad() {
        super.viewDidLoad()

        dragger = TableViewDragger(tableView: tableView)
        dragger.availableHorizontalScroll = true
        dragger.dataSource = self
        dragger.delegate = self
        dragger.alphaForCell = 0.7
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        cell.textLabel?.text = items[indexPath.section][indexPath.row]
        return cell
    }
}

extension TableViewController: TableViewDraggerDataSource, TableViewDraggerDelegate {
    func dragger(_ dragger: TableViewDragger, moveDraggingAt indexPath: IndexPath, newIndexPath: IndexPath) -> Bool {
        let item = items[indexPath.section][indexPath.row]
        items[indexPath.section].remove(at: indexPath.row)
        items[newIndexPath.section].insert(item, at: newIndexPath.row)

        tableView.moveRow(at: indexPath, to: newIndexPath)

        return true
    }
}
