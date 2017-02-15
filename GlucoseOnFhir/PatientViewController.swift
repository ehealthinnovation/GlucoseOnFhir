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
        case section0, section1, section2, section3, count
        
        public func description() -> String {
            switch self {
            case .section0:
                return "Name"
            case .section1:
                return "Telecom"
            case .section2:
                return "Address"
            case .section3:
                return "Birthdate"
            case .count:
                fatalError("invalid")
            }
        }
        
        public func rowCount() -> Int {
            switch self {
            case .section0:
                return 2
            case .section1:
                return 3
            case .section2:
                return 4
            case .section3:
                return 1
            case .count:
                fatalError("invalid")
            }
        }
        
        enum Section0 : Int {
            case givenName, familyName, count
        }
        enum Section1 : Int {
            case system, value, use, count
        }
        enum Section2 : Int {
            case line, city, postalCode, country, count
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
                    case Section.Section0.givenName.rawValue:
                        cell.textLabel!.text = self.patient.name?.first?.given?.first?.description
                        cell.detailTextLabel!.text = "given name"
                    case Section.Section0.familyName.rawValue:
                        cell.textLabel!.text = self.patient.name?.first?.family?.first?.description
                        cell.detailTextLabel!.text = "family name"
                    default:
                        cell.textLabel!.text = ""
                        cell.detailTextLabel!.text = ""
                }
            case Section.section1.rawValue:
                switch(indexPath.row) {
                case Section.Section1.system.rawValue:
                    cell.textLabel!.text = self.patient.telecom?.first?.system?.description
                    cell.detailTextLabel!.text = "system"
                case Section.Section1.value.rawValue:
                    cell.textLabel!.text = self.patient.telecom?.first?.value?.description
                    cell.detailTextLabel!.text = "value"
                case Section.Section1.use.rawValue:
                    cell.textLabel!.text = self.patient.telecom?.first?.use?.description
                    cell.detailTextLabel!.text = "use"
                default:
                    cell.textLabel!.text = ""
                    cell.detailTextLabel!.text = ""
                }
            case Section.section2.rawValue:
                switch(indexPath.row) {
                case Section.Section2.line.rawValue:
                    cell.textLabel!.text = self.patient.address?.first?.line?.first?.description
                    cell.detailTextLabel!.text = "line"
                case Section.Section2.city.rawValue:
                    cell.textLabel!.text = self.patient.address?.first?.city?.description
                    cell.detailTextLabel!.text = "city"
                case Section.Section2.postalCode.rawValue:
                    cell.textLabel!.text = self.patient.address?.first?.postalCode?.description
                    cell.detailTextLabel!.text = "postal code"
                case Section.Section2.country.rawValue:
                    cell.textLabel!.text = self.patient.address?.first?.country?.description
                    cell.detailTextLabel!.text = "country"
                default:
                    cell.textLabel!.text = ""
                    cell.detailTextLabel!.text = ""
                }
            case Section.section3.rawValue:
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
