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
        case identifier, type, manufacturer, model, count
        
        public func description() -> String {
            switch self {
            case .identifier:
                return "Identifier"
            case .type:
                return "Type"
            case .manufacturer:
                return "Manufacturer"
            case .model:
                return "Model"
            case .count:
                fatalError("invalid")
            }
        }
        
        public func rowCount() -> Int {
            switch self {
            case .identifier:
                return Identifier.count.rawValue
            case .type:
                return WithType.count.rawValue
            case .manufacturer:
                return Manufacturer.count.rawValue
            case .model:
                return Model.count.rawValue
            case .count:
                fatalError("invalid")
            }
        }
        
        enum Identifier : Int {
            case typeCodingSystem, typeCodingCode, system, value, count
        }
        enum WithType : Int {
            case codingSystem, codingCode, codingDisplay, text, count
        }
        enum Manufacturer : Int {
            case manufacturer, count
        }
        enum Model : Int {
            case model, count
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Table data source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.identifier.rawValue:
            return Section.identifier.rowCount()
        case Section.type.rawValue:
            return Section.type.rowCount()
        case Section.manufacturer.rawValue:
            return Section.manufacturer.rowCount()
        case Section.model.rawValue:
            return Section.model.rowCount()
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
        
        switch indexPath.section {
        case Section.identifier.rawValue:
            switch(indexPath.row) {
            case Section.Identifier.typeCodingSystem.rawValue:
                cell.textLabel!.text = self.device.identifier?.first?.type?.coding?.first?.system?.description
                cell.detailTextLabel!.text = "type->coding->system"
            case Section.Identifier.typeCodingCode.rawValue:
                cell.textLabel!.text = self.device.identifier?.first?.type?.coding?.first?.code?.description
                cell.detailTextLabel!.text = "type->coding->code"
            case Section.Identifier.system.rawValue:
                cell.textLabel!.text = self.device.identifier?.first?.system?.description
                cell.detailTextLabel!.text = "system"
            case Section.Identifier.value.rawValue:
                cell.textLabel!.text = self.device.identifier?.first?.value?.description
                cell.detailTextLabel!.text = "value"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case Section.type.rawValue:
            switch(indexPath.row) {
            case Section.WithType.codingSystem.rawValue:
                cell.textLabel!.text = self.device.type?.coding?.first?.system?.description
                cell.detailTextLabel!.text = "coding->system"
            case Section.WithType.codingCode.rawValue:
                cell.textLabel!.text = self.device.type?.coding?.first?.code?.description
                cell.detailTextLabel!.text = "coding->code"
            case Section.WithType.codingDisplay.rawValue:
                cell.textLabel!.text = self.device.type?.coding?.first?.display?.description
                cell.detailTextLabel!.text = "coding->display"
            case Section.WithType.text.rawValue:
                cell.textLabel!.text = self.device.type?.text?.description
                cell.detailTextLabel!.text = "text"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case Section.manufacturer.rawValue:
            cell.textLabel!.text = self.device.manufacturer?.description
            cell.detailTextLabel!.text = "manufacturer"
        case Section.model.rawValue:
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
        case Section.identifier.rawValue:
            return Section.identifier.description()
        case Section.type.rawValue:
            return Section.type.description()
        case Section.manufacturer.rawValue:
            return Section.manufacturer.description()
        case Section.model.rawValue:
            return Section.model.description()
        default:
            return ""
        }
    }

    //MARK: table delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
