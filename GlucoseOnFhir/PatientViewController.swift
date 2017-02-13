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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Table data source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 3
        case 2:
            return 4
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
                        cell.textLabel!.text = self.patient.name?.first?.given?.first?.description
                        cell.detailTextLabel!.text = "given name"
                    case 1:
                        cell.textLabel!.text = self.patient.name?.first?.family?.first?.description
                        cell.detailTextLabel!.text = "family name"
                    default:
                        cell.textLabel!.text = ""
                        cell.detailTextLabel!.text = ""
                }
            case 1:
                switch(indexPath.row) {
                case 0:
                    cell.textLabel!.text = self.patient.telecom?.first?.system?.description
                    cell.detailTextLabel!.text = "system"
                case 1:
                    cell.textLabel!.text = self.patient.telecom?.first?.value?.description
                    cell.detailTextLabel!.text = "value"
                case 2:
                    cell.textLabel!.text = self.patient.telecom?.first?.use?.description
                    cell.detailTextLabel!.text = "use"
                default:
                    cell.textLabel!.text = ""
                    cell.detailTextLabel!.text = ""
                }
            case 2:
                switch(indexPath.row) {
                case 0:
                    cell.textLabel!.text = self.patient.address?.first?.line?.first?.description
                    cell.detailTextLabel!.text = "line"
                case 1:
                    cell.textLabel!.text = self.patient.address?.first?.city?.description
                    cell.detailTextLabel!.text = "city"
                case 2:
                    cell.textLabel!.text = self.patient.address?.first?.postalCode?.description
                    cell.detailTextLabel!.text = "postal code"
                case 3:
                    cell.textLabel!.text = self.patient.address?.first?.country?.description
                    cell.detailTextLabel!.text = "country"
                default:
                    cell.textLabel!.text = ""
                    cell.detailTextLabel!.text = ""
                }
            case 3:
                cell.textLabel!.text = self.patient.birthDate?.description
                cell.detailTextLabel!.text = "birthDate"
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
            return "Name"
        case 1:
            return "Telecom"
        case 2:
            return "Address"
        case 3:
            return "Birthdate"
        default:
            return ""
        }
    }
    
    //MARK: table delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAtIndexPath")
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func refreshTable() {
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
}
