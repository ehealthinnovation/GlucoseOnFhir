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
    let sectionHeaderHeight: CGFloat = 75
    
    enum Section : Int {
        case section0, section1, section2, section3, count
        
        public func description() -> String {
            switch self {
            case .section0:
                return "Identifier"
            case .section1:
                return "Type"
            case .section2:
                return "Manufacturer"
            case .section3:
                return "Model"
            case .count:
                fatalError("invalid")
            }
        }
        
        public func rowCount() -> Int {
            switch self {
            case .section0:
                return 4
            case .section1:
                return 4
            case .section2:
                return 1
            case .section3:
                return 1
            case .count:
                fatalError("invalid")
            }
        }
        
        enum Section0 : Int {
            case typeCodingSystem, typeCodingCode, system, value, count
        }
        enum Section1 : Int {
            case codingSystem, codingCode, codingDisplay, text, count
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Table data source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.section0.rawValue:
            return Section.section0.rowCount()
        case Section.section1.rawValue:
            return Section.section1.rowCount()
        case Section.section2.rawValue:
            return Section.section2.rowCount()
        case Section.section3.rawValue:
            return Section.section3.rowCount()
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
        
        switch indexPath.section {
        case Section.section0.rawValue:
            switch(indexPath.row) {
            case Section.Section0.typeCodingSystem.rawValue:
                cell.textLabel!.text = self.device.identifier?.first?.type?.coding?.first?.system?.description
                cell.detailTextLabel!.text = "type->coding->system"
            case Section.Section0.typeCodingCode.rawValue:
                cell.textLabel!.text = self.device.identifier?.first?.type?.coding?.first?.code?.description
                cell.detailTextLabel!.text = "type->coding->code"
            case Section.Section0.system.rawValue:
                cell.textLabel!.text = self.device.identifier?.first?.system?.description
                cell.detailTextLabel!.text = "system"
            case Section.Section0.value.rawValue:
                cell.textLabel!.text = self.device.identifier?.first?.value?.description
                cell.detailTextLabel!.text = "value"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case Section.section1.rawValue:
            switch(indexPath.row) {
            case Section.Section1.codingSystem.rawValue:
                cell.textLabel!.text = self.device.type?.coding?.first?.system?.description
                cell.detailTextLabel!.text = "coding->system"
            case Section.Section1.codingCode.rawValue:
                cell.textLabel!.text = self.device.type?.coding?.first?.code?.description
                cell.detailTextLabel!.text = "coding->code"
            case Section.Section1.codingDisplay.rawValue:
                cell.textLabel!.text = self.device.type?.coding?.first?.display?.description
                cell.detailTextLabel!.text = "coding->display"
            case Section.Section1.text.rawValue:
                cell.textLabel!.text = self.device.type?.text?.description
                cell.detailTextLabel!.text = "text"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case Section.section2.rawValue:
            cell.textLabel!.text = self.device.manufacturer?.description
            cell.detailTextLabel!.text = "manufacturer"
        case Section.section3.rawValue:
            cell.textLabel!.text = self.device.model?.description
            cell.detailTextLabel!.text = "model"
        default:
            break
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.sectionHeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.section0.rawValue:
            return Section.section0.description()
        case Section.section1.rawValue:
            return Section.section1.description()
        case Section.section2.rawValue:
            return Section.section2.description()
        case Section.section3.rawValue:
            return Section.section3.description()
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
