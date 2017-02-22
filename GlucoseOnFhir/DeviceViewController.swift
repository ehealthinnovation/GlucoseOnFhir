//
//  DeviceViewController.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 1/16/17.
//  Copyright © 2017 eHealth Innovation. All rights reserved.
//

// swiftlint:disable nesting
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

import Foundation
import UIKit
import SMART

class DeviceViewController: UITableViewController {
    public var device: Device!
    let cellIdentifier = "DeviceCellIdentifier"
    let sectionHeaderHeight: CGFloat = 75
    
    enum Section: Int {
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
        
        enum Identifier: Int {
            case typeCodingSystem, typeCodingCode, system, value, count
        }
        enum WithType: Int {
            case codingSystem, codingCode, codingDisplay, text, count
        }
        enum Manufacturer: Int {
            case manufacturer, count
        }
        enum Model: Int {
            case model, count
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Table data source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = Section(rawValue: section)
        return (sectionType?.rowCount())!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
    
        guard let section = Section(rawValue:indexPath.section) else {
            fatalError("invalid section")
        }
        
        switch section {
            case .identifier:
                guard let row = Section.Identifier(rawValue:indexPath.row) else { fatalError("invalid row") }
                switch row {
                    case .typeCodingSystem:
                        cell.textLabel!.text = self.device.identifier?.first?.type?.coding?.first?.system?.description
                        cell.detailTextLabel!.text = "type->coding->system"
                    case .typeCodingCode:
                        cell.textLabel!.text = self.device.identifier?.first?.type?.coding?.first?.code?.description
                        cell.detailTextLabel!.text = "type->coding->code"
                    case .system:
                        cell.textLabel!.text = self.device.identifier?.first?.system?.description
                        cell.detailTextLabel!.text = "system"
                    case .value:
                        cell.textLabel!.text = self.device.identifier?.first?.value?.description
                        cell.detailTextLabel!.text = "value"
                    default:
                        cell.textLabel!.text = ""
                        cell.detailTextLabel!.text = ""
                }
            case .type:
                guard let row = Section.WithType(rawValue:indexPath.row) else { fatalError("invalid row") }
                switch row {
                    case .codingSystem:
                        cell.textLabel!.text = self.device.type?.coding?.first?.system?.description
                        cell.detailTextLabel!.text = "coding->system"
                    case .codingCode:
                        cell.textLabel!.text = self.device.type?.coding?.first?.code?.description
                        cell.detailTextLabel!.text = "coding->code"
                    case .codingDisplay:
                        cell.textLabel!.text = self.device.type?.coding?.first?.display?.description
                        cell.detailTextLabel!.text = "coding->display"
                    case .text:
                        cell.textLabel!.text = self.device.type?.text?.description
                        cell.detailTextLabel!.text = "text"
                    default:
                        cell.textLabel!.text = ""
                        cell.detailTextLabel!.text = ""
                }
            case .manufacturer:
                cell.textLabel!.text = self.device.manufacturer?.description
                cell.detailTextLabel!.text = "manufacturer"
            case .model:
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
        let sectionType = Section(rawValue: section)
        return sectionType?.description() ?? "none"
    }

    // MARK: table delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
