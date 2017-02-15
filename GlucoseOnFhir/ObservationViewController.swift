//
//  ObservationViewController.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 1/16/17.
//  Copyright © 2017 eHealth Innovation. All rights reserved.
//

import Foundation
import UIKit
import SMART

class ObservationViewController: UITableViewController {
    public var observation: Observation!
    let cellIdentifier = "ObservationCellIdentifier"
    let sectionHeaderHeight: CGFloat = 75
    
    // TO-DO:
    enum Section : Int {
        case section0, section1, section2, section3, section4, section5, section6, count
        
        public func description() -> String {
            switch self {
            case .section0:
                return "Code"
            case .section1:
                return "Subject"
            case .section2:
                return "Effective Period"
            case .section3:
                return "Performer"
            case .section4:
                return "Value Quantity"
            case .section5:
                return "Device"
            case .section6:
                return "Meal Context"
            case .count:
                fatalError("invalid")
            }
        }
        
        public func rowCount() -> Int {
            switch self {
            case .section0:
                return 3
            case .section1:
                return 1
            case .section2:
                return 2
            case .section3:
                return 1
            case .section4:
                return 4
            case .section5:
                return 1
            case .section6:
                return 4
            case .count:
                fatalError("invalid")
            }
        }
        
        enum Section0 : Int {
            case codingSystem, codingCode, codingDisplay, count
        }
        enum Section2 : Int {
            case start, end, count
        }
        enum Section4 : Int {
            case value, unit, system, code, count
        }
        enum Section6 : Int {
            case system, code, display, url, count
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
        case Section.section4.rawValue:
            return Section.section4.rowCount()
        case Section.section5.rawValue:
            return Section.section5.rowCount()
        case Section.section6.rawValue:
            return Section.section6.rowCount()
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
        
        switch indexPath.section {
        case Section.section0.rawValue:
            switch(indexPath.row) {
            case Section.Section0.codingSystem.rawValue:
                cell.textLabel!.text = self.observation.code?.coding?.first?.system?.description
                cell.detailTextLabel!.text = "coding->system"
            case Section.Section0.codingCode.rawValue:
                cell.textLabel!.text = self.observation.code?.coding?.first?.code?.description
                cell.detailTextLabel!.text = "coding->code"
            case Section.Section0.codingDisplay.rawValue:
                cell.textLabel!.text = self.observation.code?.coding?.first?.display?.description
                cell.detailTextLabel!.text = "coding->display"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case Section.section1.rawValue:
            cell.textLabel!.text = self.observation.subject?.reference?.description
            cell.detailTextLabel!.text = "reference"
        case Section.section2.rawValue:
            switch(indexPath.row) {
            case Section.Section2.start.rawValue:
                cell.textLabel!.text = self.observation.effectivePeriod?.start?.description
                cell.detailTextLabel!.text = "start"
            case Section.Section2.end.rawValue:
                cell.textLabel!.text = self.observation.effectivePeriod?.end?.description
                cell.detailTextLabel!.text = "end"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case Section.section3.rawValue:
            cell.textLabel!.text = self.observation.performer?.first?.reference?.description
            cell.detailTextLabel!.text = "reference"
        case Section.section4.rawValue:
            switch(indexPath.row) {
            case Section.Section4.value.rawValue:
                cell.textLabel!.text = self.observation.valueQuantity?.value?.description
                cell.detailTextLabel!.text = "value"
            case Section.Section4.unit.rawValue:
                cell.textLabel!.text = self.observation.valueQuantity?.unit?.description
                cell.detailTextLabel!.text = "unit"
            case Section.Section4.system.rawValue:
                cell.textLabel!.text = self.observation.valueQuantity?.system?.description
                cell.detailTextLabel!.text = "system"
            case Section.Section4.code.rawValue:
                cell.textLabel!.text = self.observation.valueQuantity?.code?.description
                cell.detailTextLabel!.text = "code"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case Section.section5.rawValue:
            cell.textLabel!.text = self.observation.device?.reference?.description
            cell.detailTextLabel!.text = "reference"
        case Section.section6.rawValue:
            switch(indexPath.row) {
            case Section.Section6.system.rawValue:
                cell.textLabel!.text = observation.extension_fhir?.first?.valueCoding?.system?.description
                cell.detailTextLabel!.text = "system"
            case Section.Section6.code.rawValue:
                cell.textLabel!.text = observation.extension_fhir?.first?.valueCoding?.code?.description
                cell.detailTextLabel!.text = "code"
            case Section.Section6.display.rawValue:
                cell.textLabel!.text = observation.extension_fhir?.first?.valueCoding?.display?.description
                cell.detailTextLabel!.text = "display"
            case Section.Section6.url.rawValue:
                cell.textLabel!.text = observation.extension_fhir?.first?.url?.description
                cell.detailTextLabel!.text = "url"
            default:
                ()
            }
        default:
            break
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if (observation.extension_fhir?.count) != nil {
            return Section.count.rawValue
        }
        
        return Section.count.rawValue - 1
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
        case Section.section4.rawValue:
            return Section.section4.description()
        case Section.section5.rawValue:
            return Section.section5.description()
        case Section.section6.rawValue:
            return Section.section6.description()
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
