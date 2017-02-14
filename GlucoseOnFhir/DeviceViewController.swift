//
//  DeviceViewController.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 1/16/17.
//  Copyright © 2017 eHealth Innovation. All rights reserved.
//

import Foundation
import UIKit
import SMART

class DeviceViewController: UITableViewController {
    public var device: Device!
    let cellIdentifier = "DeviceCellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Table data source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 4
        case 1:
            return 4
        case 2:
            return 1
        case 3:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
        
        switch indexPath.section {
        case 0:
            switch(indexPath.row) {
            case 0:
                cell.textLabel!.text = self.device.identifier?.first?.type?.coding?.first?.system?.description
                cell.detailTextLabel!.text = "type->coding->system"
            case 1:
                cell.textLabel!.text = self.device.identifier?.first?.type?.coding?.first?.code?.description
                cell.detailTextLabel!.text = "type->coding->code"
            case 2:
                cell.textLabel!.text = self.device.identifier?.first?.system?.description
                cell.detailTextLabel!.text = "system"
            case 3:
                cell.textLabel!.text = self.device.identifier?.first?.value?.description
                cell.detailTextLabel!.text = "value"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case 1:
            switch(indexPath.row) {
            case 0:
                cell.textLabel!.text = self.device.type?.coding?.first?.system?.description
                cell.detailTextLabel!.text = "coding->system"
            case 1:
                cell.textLabel!.text = self.device.type?.coding?.first?.code?.description
                cell.detailTextLabel!.text = "coding->code"
            case 2:
                cell.textLabel!.text = self.device.type?.coding?.first?.display?.description
                cell.detailTextLabel!.text = "coding->display"
            case 3:
                cell.textLabel!.text = self.device.type?.text?.description
                cell.detailTextLabel!.text = "text"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case 2:
            cell.textLabel!.text = self.device.manufacturer?.description
            cell.detailTextLabel!.text = "manufacturer"
        case 3:
            cell.textLabel!.text = self.device.model?.description
            cell.detailTextLabel!.text = "model"
        default:
            print("")
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Identifier"
        case 1:
            return "Type"
        case 2:
            return "Manufacturer"
        case 3:
            return "Model"
        default:
            return ""
        }
    }

    //MARK: table delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAtIndexPath")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
