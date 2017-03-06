//
//  HealthCell.swift
//  HealthKitDemo
//
//  Created by Mike Baglio Jr. on 3/5/17.
//  Copyright © 2017 Emmbi Mobile LLC. All rights reserved.
//

import UIKit


class HealthCell: UITableViewCell {
    
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var value: UILabel!
    
    override func prepareForReuse() {
        self.value.text = nil
        self.date.text = nil
    }
}
