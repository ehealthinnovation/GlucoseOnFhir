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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Table data source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return 1
        case 2:
            return 2
        case 3:
            return 1
        case 4:
            return 4
        case 5:
            return 1
        case 6:
            return 4
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
                cell.textLabel!.text = self.observation.code?.coding?.first?.system?.description
                cell.detailTextLabel!.text = "coding->system"
            case 1:
                cell.textLabel!.text = self.observation.code?.coding?.first?.code?.description
                cell.detailTextLabel!.text = "coding->code"
            case 2:
                cell.textLabel!.text = self.observation.code?.coding?.first?.display?.description
                cell.detailTextLabel!.text = "coding->display"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case 1:
            cell.textLabel!.text = self.observation.subject?.reference?.description
            cell.detailTextLabel!.text = "reference"
        case 2:
            switch(indexPath.row) {
            case 0:
                cell.textLabel!.text = self.observation.effectivePeriod?.start?.description
                cell.detailTextLabel!.text = "start"
            case 1:
                cell.textLabel!.text = self.observation.effectivePeriod?.end?.description
                cell.detailTextLabel!.text = "end"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case 3:
            cell.textLabel!.text = self.observation.performer?.first?.reference?.description
            cell.detailTextLabel!.text = "reference"
        case 4:
            switch(indexPath.row) {
            case 0:
                cell.textLabel!.text = self.observation.valueQuantity?.value?.description
                cell.detailTextLabel!.text = "value"
            case 1:
                cell.textLabel!.text = self.observation.valueQuantity?.unit?.description
                cell.detailTextLabel!.text = "unit"
            case 2:
                cell.textLabel!.text = self.observation.valueQuantity?.system?.description
                cell.detailTextLabel!.text = "system"
            case 3:
                cell.textLabel!.text = self.observation.valueQuantity?.code?.description
                cell.detailTextLabel!.text = "code"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
            }
        case 5:
            cell.textLabel!.text = self.observation.device?.reference?.description
            cell.detailTextLabel!.text = "reference"
        case 6:
            switch(indexPath.row) {
            case 0:
                cell.textLabel!.text = observation.extension_fhir?.first?.valueCoding?.system?.description
                cell.detailTextLabel!.text = "system"
            case 1:
                cell.textLabel!.text = observation.extension_fhir?.first?.valueCoding?.code?.description
                cell.detailTextLabel!.text = "code"
            case 2:
                cell.textLabel!.text = observation.extension_fhir?.first?.valueCoding?.display?.description
                cell.detailTextLabel!.text = "display"
            case 3:
                cell.textLabel!.text = observation.extension_fhir?.first?.url?.description
                cell.detailTextLabel!.text = "url"
            default:
                ()
            }
        default:
            print("")
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if (observation.extension_fhir?.count) != nil {
            return 7
        }
        
        return 6
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Code"
        case 1:
            return "Subject"
        case 2:
            return "Effective Period"
        case 3:
            return "Performer"
        case 4:
            return "Value Quantity"
        case 5:
            return "Device"
        case 6:
            return "Meal Context"
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
