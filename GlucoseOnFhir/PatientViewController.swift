//
//  PatientViewController.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 1/16/17.
//  Copyright © 2017 eHealth Innovation. All rights reserved.
//

// swiftlint:disable function_body_length
// swiftlint:disable nesting

import Foundation
import UIKit
import SMART

class PatientViewController: UITableViewController {
    public var patient: Patient!
    let cellIdentifier = "PatientCellIdentifier"
    let sectionHeaderHeight: CGFloat = 75
    
    enum Section: Int {
        case name, telecom, address, birthdate, count
        
        public func description() -> String {
            switch self {
            case .name:
                return "Name"
            case .telecom:
                return "Telecom"
            case .address:
                return "Address"
            case .birthdate:
                return "Birthdate"
            case .count:
                fatalError("invalid")
            }
        }
        
        public func rowCount() -> Int {
            switch self {
            case .name:
                return Name.count.rawValue
            case .telecom:
                return Telecom.count.rawValue
            case .address:
                return Address.count.rawValue
            case .birthdate:
                return Birthdate.count.rawValue
            case .count:
                fatalError("invalid")
            }
        }
        
        enum Name: Int {
            case givenName, familyName, count
        }
        enum Telecom: Int {
            case system, value, use, count
        }
        enum Address: Int {
            case line, city, postalCode, country, count
        }
        enum Birthdate: Int {
            case birthdate, count
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
    
    // swiftlint:disable:next cyclomatic_complexity
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
        
        guard let section = Section(rawValue:indexPath.section) else {
            fatalError("invalid section")
        }
        
        switch section {
        case .name:
            guard let row = Section.Name(rawValue:indexPath.row) else { fatalError("invalid row") }
            switch row {
            case .givenName:
                cell.textLabel!.text = self.patient.name?.first?.given?.first?.description
                cell.detailTextLabel!.text = "given name"
            case .familyName:
                cell.textLabel!.text = String(describing: self.patient.name!.first!.family!.string)
                cell.detailTextLabel!.text = "family name"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case .telecom:
            guard let row = Section.Telecom(rawValue:indexPath.row) else { fatalError("invalid row") }
            switch row {
            case .system:
                cell.textLabel!.text = String(describing: self.patient.telecom!.first!.system!.rawValue)
                cell.detailTextLabel!.text = "system"
            case .value:
                cell.textLabel!.text = self.patient.telecom?.first?.value?.description
                cell.detailTextLabel!.text = "value"
            case .use:
                cell.textLabel!.text = String(describing: self.patient.telecom!.first!.use!.rawValue)
                cell.detailTextLabel!.text = "use"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case .address:
            guard let row = Section.Address(rawValue:indexPath.row) else { fatalError("invalid row") }
            switch row {
            case .line:
                cell.textLabel!.text = self.patient.address?.first?.line?.first?.description
                cell.detailTextLabel!.text = "line"
            case .city:
                cell.textLabel!.text = self.patient.address?.first?.city?.description
                cell.detailTextLabel!.text = "city"
            case .postalCode:
                cell.textLabel!.text = self.patient.address?.first?.postalCode?.description
                cell.detailTextLabel!.text = "postal code"
            case .country:
                cell.textLabel!.text = self.patient.address?.first?.country?.description
                cell.detailTextLabel!.text = "country"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case .birthdate:
            cell.textLabel!.text = self.patient.birthDate?.description
            cell.detailTextLabel!.text = "birthDate"
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
