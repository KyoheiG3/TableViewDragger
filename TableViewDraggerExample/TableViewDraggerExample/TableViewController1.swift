//
//  TableViewController1.swift
//  TableViewDraggerExample
//
//  Created by Kyohei Ito on 2017/12/08.
//  Copyright © 2017年 kyohei_ito. All rights reserved.
//

import UIKit
import TableViewDragger

class TableViewController1: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var dragger: TableViewDragger!
    var items: [String] = (0..<100).map { "\($0)" }

    override func viewDidLoad() {
        super.viewDidLoad()

        dragger = TableViewDragger(tableView: tableView)
        dragger.dataSource = self
        dragger.delegate = self
        dragger.alphaForCell = 0.7
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}

extension TableViewController1: TableViewDraggerDataSource, TableViewDraggerDelegate {
    func dragger(_ dragger: TableViewDragger, moveDraggingAt indexPath: IndexPath, newIndexPath: IndexPath) -> Bool {
        let item = items[indexPath.row]
        items.remove(at: indexPath.row)
        items.insert(item, at: newIndexPath.row)
        tableView.moveRow(at: indexPath, to: newIndexPath)

        return true
    }
}
