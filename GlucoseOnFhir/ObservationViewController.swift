//
//  ObservationViewController.swift
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
import CCGlucose

class ObservationViewController: UITableViewController {
    private var observation: Observation!
    public var measurement: GlucoseMeasurement!
    
    let cellIdentifier = "ObservationCellIdentifier"
    let sectionHeaderHeight: CGFloat = 75
    
    enum Section: Int {
        case code, subject, effectivePeriod, performer, valueQuantity, device, mealContext, count
        
        public func description() -> String {
            switch self {
            case .code:
                return "Code"
            case .subject:
                return "Subject"
            case .effectivePeriod:
                return "Effective Period"
            case .performer:
                return "Performer"
            case .valueQuantity:
                return "Value Quantity"
            case .device:
                return "Device"
            case .mealContext:
                return "Meal Context"
            case .count:
                fatalError("invalid")
            }
        }
        
        public func rowCount() -> Int {
            switch self {
            case .code:
                return Code.count.rawValue
            case .subject:
                return Subject.count.rawValue
            case .effectivePeriod:
                return EffectivePeriod.count.rawValue
            case .performer:
                return Performer.count.rawValue
            case .valueQuantity:
                return ValueQuantity.count.rawValue
            case .device:
                return Device.count.rawValue
            case .mealContext:
                return MealContext.count.rawValue
            case .count:
                fatalError("invalid")
            }
        }
        
        enum Code: Int {
            case codingSystem, codingCode, codingDisplay, count
        }
        enum Subject: Int {
            case subject, count
        }
        enum EffectivePeriod: Int {
            case start, end, count
        }
        enum Performer: Int {
            case performer, count
        }
        enum ValueQuantity: Int {
            case value, unit, system, code, count
        }
        enum Device: Int {
            case device, count
        }
        enum MealContext: Int {
            case system, code, display, url, count
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.observation = BGMFhir.BGMFhirInstance.measurementToObservation(measurement: measurement)
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
        case .code:
            guard let row = Section.Code(rawValue:indexPath.row) else { fatalError("invalid row") }
            switch row {
            case .codingSystem:
                cell.textLabel!.text = self.observation.code?.coding?.first?.system?.description
                cell.detailTextLabel!.text = "coding->system"
            case .codingCode:
                cell.textLabel!.text = self.observation.code?.coding?.first?.code?.description
                cell.detailTextLabel!.text = "coding->code"
            case .codingDisplay:
                cell.textLabel!.text = self.observation.code?.coding?.first?.display?.description
                cell.detailTextLabel!.text = "coding->display"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case .subject:
            cell.textLabel!.text = self.observation.subject?.reference?.description
            cell.detailTextLabel!.text = "reference"
        case .effectivePeriod:
            guard let row = Section.EffectivePeriod(rawValue:indexPath.row) else { fatalError("invalid row") }
            switch row {
            case .start:
                cell.textLabel!.text = self.observation.effectivePeriod?.start?.description
                cell.detailTextLabel!.text = "start"
            case .end:
                cell.textLabel!.text = self.observation.effectivePeriod?.end?.description
                cell.detailTextLabel!.text = "end"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case .performer:
            cell.textLabel!.text = self.observation.performer?.first?.reference?.description
            cell.detailTextLabel!.text = "reference"
        case .valueQuantity:
            guard let row = Section.ValueQuantity(rawValue:indexPath.row) else { fatalError("invalid row") }
            switch row {
            case .value:
                cell.textLabel!.text = self.observation.valueQuantity?.value?.description
                cell.detailTextLabel!.text = "value"
            case .unit:
                cell.textLabel!.text = self.observation.valueQuantity?.unit?.description
                cell.detailTextLabel!.text = "unit"
            case .system:
                cell.textLabel!.text = self.observation.valueQuantity?.system?.description
                cell.detailTextLabel!.text = "system"
            case .code:
                cell.textLabel!.text = self.observation.valueQuantity?.code?.description
                cell.detailTextLabel!.text = "code"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case .device:
            cell.textLabel!.text = self.observation.device?.reference?.description
            cell.detailTextLabel!.text = "reference"
        case .mealContext:
            guard let row = Section.MealContext(rawValue:indexPath.row) else { fatalError("invalid row") }
            switch row {
            case .system:
                cell.textLabel!.text = observation.extension_fhir?.first?.valueCoding?.system?.description
                cell.detailTextLabel!.text = "system"
            case .code:
                cell.textLabel!.text = observation.extension_fhir?.first?.valueCoding?.code?.description
                cell.detailTextLabel!.text = "code"
            case .display:
                cell.textLabel!.text = observation.extension_fhir?.first?.valueCoding?.display?.description
                cell.detailTextLabel!.text = "display"
            case .url:
                cell.textLabel!.text = observation.extension_fhir?.first?.url?.description
                cell.detailTextLabel!.text = "url"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
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
        let sectionType = Section(rawValue: section)
        return sectionType?.description() ?? "none"
    }

    // MARK: table delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
