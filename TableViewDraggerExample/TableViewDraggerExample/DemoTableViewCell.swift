//
//  DemoTableViewCell.swift
//  TableViewDraggerExample
//
//  Created by Kyohei Ito on 2015/09/25.
//  Copyright © 2015年 kyohei_ito. All rights reserved.
//

import UIKit

class DemoTableViewCell: UITableViewCell {
    @IBOutlet weak var demoImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor.clearColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
