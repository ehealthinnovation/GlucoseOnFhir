//
//  Refreshable.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 2/14/17.
//  Copyright © 2017 eHealth Innovation. All rights reserved.
//

import Foundation
import UIKit

protocol Refreshable {
    func refresh()
}

extension Refreshable where Self: UITableViewController {
    func refresh() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
