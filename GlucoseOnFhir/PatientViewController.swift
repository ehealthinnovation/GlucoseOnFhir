//
//  PatientViewController.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 1/16/17.
//  Copyright © 2017 eHealth Innovation. All rights reserved.
//

import Foundation
import UIKit
import SMART

class PatientViewController: UITableViewController {
    public var patient: Patient!
    let cellIdentifier = "PatientCellIdentifier"
    let sectionHeaderHeight: CGFloat = 75
    
    enum Section : Int {
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
        
        enum Name : Int {
            case givenName, familyName, count
        }
        enum Telecom : Int {
            case system, value, use, count
        }
        enum Address : Int {
            case line, city, postalCode, country, count
        }
        enum Birthdate : Int {
            case birthdate, count
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Table data source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.name.rawValue:
            return Section.name.rowCount()
        case Section.telecom.rawValue:
            return Section.telecom.rowCount()
        case Section.address.rawValue:
            return Section.address.rowCount()
        case Section.birthdate.rawValue:
            return Section.birthdate.rowCount()
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
        
        switch indexPath.section {
            case Section.name.rawValue:
                switch(indexPath.row) {
                    case Section.Name.givenName.rawValue:
                        cell.textLabel!.text = self.patient.name?.first?.given?.first?.description
                        cell.detailTextLabel!.text = "given name"
                    case Section.Name.familyName.rawValue:
                        cell.textLabel!.text = self.patient.name?.first?.family?.first?.description
                        cell.detailTextLabel!.text = "family name"
                    default:
                        cell.textLabel!.text = ""
                        cell.detailTextLabel!.text = ""
                }
            case Section.telecom.rawValue:
                switch(indexPath.row) {
                case Section.Telecom.system.rawValue:
                    cell.textLabel!.text = self.patient.telecom?.first?.system?.description
                    cell.detailTextLabel!.text = "system"
                case Section.Telecom.value.rawValue:
                    cell.textLabel!.text = self.patient.telecom?.first?.value?.description
                    cell.detailTextLabel!.text = "value"
                case Section.Telecom.use.rawValue:
                    cell.textLabel!.text = self.patient.telecom?.first?.use?.description
                    cell.detailTextLabel!.text = "use"
                default:
                    cell.textLabel!.text = ""
                    cell.detailTextLabel!.text = ""
                }
            case Section.address.rawValue:
                switch(indexPath.row) {
                case Section.Address.line.rawValue:
                    cell.textLabel!.text = self.patient.address?.first?.line?.first?.description
                    cell.detailTextLabel!.text = "line"
                case Section.Address.city.rawValue:
                    cell.textLabel!.text = self.patient.address?.first?.city?.description
                    cell.detailTextLabel!.text = "city"
                case Section.Address.postalCode.rawValue:
                    cell.textLabel!.text = self.patient.address?.first?.postalCode?.description
                    cell.detailTextLabel!.text = "postal code"
                case Section.Address.country.rawValue:
                    cell.textLabel!.text = self.patient.address?.first?.country?.description
                    cell.detailTextLabel!.text = "country"
                default:
                    cell.textLabel!.text = ""
                    cell.detailTextLabel!.text = ""
                }
            case Section.birthdate.rawValue:
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
        switch section {
        case Section.name.rawValue:
            return Section.name.description()
        case Section.telecom.rawValue:
            return Section.telecom.description()
        case Section.address.rawValue:
            return Section.address.description()
        case Section.birthdate.rawValue:
            return Section.birthdate.description()
        default:
            return ""
        }
    }
    
    //MARK: table delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
