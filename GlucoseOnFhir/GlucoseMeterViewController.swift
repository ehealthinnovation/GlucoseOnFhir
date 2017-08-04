//
//  GlucoseMeterViewController.swift
//  CCBluetooth
//
//  Created by Kevin Tallevi on 7/8/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

// swiftlint:disable nesting
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable line_length
// swiftlint:disable function_body_length
// swiftlint:disable file_length
// swiftlint:disable unused_closure_parameter

import Foundation
import UIKit
import CoreBluetooth
import CCGlucose
import CCToolbox
import SMART

class GlucoseMeterViewController: UITableViewController, GlucoseProtocol, Refreshable {
    let cellIdentifier = "GlucoseMeterCellIdentifier"
    var glucoseMeterConnected: Bool! = false
    var glucoseMeter: CBPeripheral!
    var glucoseFeatures: GlucoseFeatures!
    var glucoseMeasurementCount: UInt16 = 0
    var glucoseMeasurements: [GlucoseMeasurement] = [GlucoseMeasurement]()
    var selectedGlucoseMeasurement: GlucoseMeasurement!
    
    var givenName: FHIRString = "Lisa"
    var familyName: FHIRString = "Simpson"
    
    public var patient: Patient?
    public var device: Device?
    
    struct LogMessage {
        let date: Date
        let text: String
    }
    var log: [LogMessage] = []
    
    enum Section: Int {
        case patient, glucoseMeterDevice, glucoseMeterRecordCount, glucoseMeterRecords, count
        
        public func description() -> String {
            switch self {
            case .patient:
                return "Patient"
            case .glucoseMeterDevice:
                return "Glucose Meter Device"
            case .glucoseMeterRecordCount:
                return "Glucose Meter Record Count"
            case .glucoseMeterRecords:
                return "Glucose Meter Records"
            case .count:
                fatalError("invalid")
            }
        }
    
        public func rowCount() -> Int {
            switch self {
            case .patient:
                return Patient.count.rawValue
            case .glucoseMeterDevice:
                return GlucoseMeterDevice.count.rawValue
            case .glucoseMeterRecordCount:
                return GlucoseMeterRecordCount.count.rawValue
            case .glucoseMeterRecords:
                return 1
            case .count:
                fatalError("invalid")
            }
        }
        
        enum Patient: Int {
            case patient, count
        }
        enum GlucoseMeterDevice: Int {
            case glucoseMeterDevice, count
        }
        enum GlucoseMeterRecordCount: Int {
            case glucoseMeterRecordCount, count
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("glucoseMeter: \(glucoseMeter)")
        
        Glucose.sharedInstance().glucoseDelegate = self
        Glucose.sharedInstance().connectToGlucoseMeter(glucoseMeter: glucoseMeter)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.estimatedRowHeight = 70
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        
        if glucoseMeterConnected == true {
            Glucose.sharedInstance().disconnectGlucoseMeter()
        }
    }
    
    func getMeasurment(sequenceNumber: UInt16) -> GlucoseMeasurement? {
        for measurement: GlucoseMeasurement in glucoseMeasurements {
            if measurement.sequenceNumber == sequenceNumber {
                return measurement
            }
        }
        return nil
        
    }
    
    // MARK: GlucoseProtocol
    func glucoseMeterConnected(meter: CBPeripheral) {
        print("GlucoseMeterViewController#glucoseMeterConnected")
        glucoseMeterConnected = true
    }
    
    public func glucoseMeterDisconnected(meter: CBPeripheral) {
        print("GlucoseMeterViewController#glucoseMeterDisconnected")
        glucoseMeterConnected = false
    }
    
    func numberOfStoredRecords(number: UInt16) {
        print("GlucoseMeterViewController#numberOfStoredRecords - \(number)")
        glucoseMeasurementCount = number
    
        Glucose.sharedInstance().downloadRecordsWithRange(from: 215, to: 216)
    }
    
    func glucoseMeasurement(measurement: GlucoseMeasurement) {
        //Note: This is a workaround for a bluetooth read bug that returns 0's before the record
        if measurement.glucoseConcentration > 0 {
            measurement.existsOnFHIR = false
            glucoseMeasurements.append(measurement)
        }
        
        print("glucoseMeasurements count: \(glucoseMeasurements.count)")
        self.refresh()
    }
    
    func glucoseMeasurementContext(measurementContext: GlucoseMeasurementContext) {
        print("glucoseMeasurementContext - id: \(measurementContext.sequenceNumber)")
        if let measurement = getMeasurment(sequenceNumber: measurementContext.sequenceNumber) {
            measurement.context = measurementContext
        }
    }
    
    func glucoseFeatures(features: GlucoseFeatures) {
        glucoseFeatures = features
    }
    
    public func glucoseMeterDidTransferMeasurements(error: NSError?) {
        print("glucoseMeterDidTransferMeasurements")
        if !FHIR.fhirInstance.fhirServerAddress.isEmpty {
            self.searchForFHIRResources()
        }
    }
    
    public func searchForFHIRResources() {
        DispatchQueue.once(executeToken: "glucoseOnFhir.glucoseMeterDidTransferMeasurements.runOnce") {
            BGMFhir.BGMFhirInstance.searchForPatient(given: String(describing:  BGMFhir.BGMFhirInstance.givenName), family: String(describing: BGMFhir.BGMFhirInstance.familyName)) { (bundle, error) -> Void in
                if let error = error {
                    print("error searching for patient: \(error)")
                }
                self.refresh()
                
                if bundle?.entry != nil {
                    for measurement in self.glucoseMeasurements {
                        BGMFhir.BGMFhirInstance.searchForObservation(measurement: measurement) { (bundle, error) -> Void in
                            if let error = error {
                                print("error searching for observation: \(error)")
                            }
                            self.refresh()
                        }
                    }
                }
            }
            BGMFhir.BGMFhirInstance.searchForDevice { (bundle, error) -> Void in
                if let error = error {
                    print("error searching for device: \(error)")
                }
                self.refresh()
                
                if bundle?.entry != nil {
                    BGMFhir.BGMFhirInstance.searchForSpecimen { (bundle, error) -> Void in
                        if let error = error {
                            print("error searching for specimen: \(error)")
                        }
                        
                        if bundle?.entry != nil {
                            print("specimen found")
                        }
                    }
                }
            }
        }
    }
    
    public func glucoseError(error: NSError) {
        print("glucoseError")
    }
    
    func createActivityView() -> UIActivityIndicatorView {
        let activity = UIActivityIndicatorView(frame: .zero)
        activity.sizeToFit()
        
        activity.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.gray
        activity.startAnimating()
        
        return activity
    }

    // MARK: Storyboard
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToPatient" {
            let PatientViewVC =  segue.destination as! PatientViewController
            PatientViewVC.patient = BGMFhir.BGMFhirInstance.patient
        }
        if segue.identifier == "segueToDevice" {
            let DeviceViewVC =  segue.destination as! DeviceViewController
            DeviceViewVC.device = BGMFhir.BGMFhirInstance.device
        }
        if segue.identifier == "segueToObservation" {
            let ObservationViewVC =  segue.destination as! ObservationViewController
            ObservationViewVC.measurement = selectedGlucoseMeasurement
        }
    }
    
    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue:section) else {
            fatalError("invalid section")
        }
        
        switch section {
            case .glucoseMeterRecords:
                return glucoseMeasurements.count
            default:
                return (section.rowCount())
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
        cell.textLabel?.numberOfLines = 0
        
        guard let section = Section(rawValue:indexPath.section) else {
            fatalError("invalid section")
        }
        
        switch section {
            case .patient:
                cell.textLabel!.text = "Given Name: \(self.givenName)\nFamily Name: \(self.familyName)"
                
                if BGMFhir.BGMFhirInstance.patient != nil {
                    cell.detailTextLabel!.text = String(describing: "Patient FHIR ID: \(String(describing: BGMFhir.BGMFhirInstance.patient!.id!))")
                    cell.accessoryView = nil
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.detailTextLabel!.text = "Patient: Tap to upload"
                }
            case .glucoseMeterDevice:
                if let manufacturer = Glucose.sharedInstance().manufacturerName {
                    cell.textLabel!.text = "Manufacturer: \(manufacturer)"
                }
                if let modelNumber = Glucose.sharedInstance().modelNumber {
                    cell.textLabel?.text?.append("\nModel: \(modelNumber)")
                }
                if let serialNumber = Glucose.sharedInstance().serialNumber {
                    cell.textLabel?.text?.append("\nSerial: \(serialNumber)")
                }
                if BGMFhir.BGMFhirInstance.device != nil {
                    cell.detailTextLabel!.text = String(describing: "Device FHIR ID: \(String(describing: BGMFhir.BGMFhirInstance.device!.id!))")
                    cell.accessoryView = nil
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.detailTextLabel!.text = "Device: Tap to upload"
                }
            case .glucoseMeterRecordCount:
                cell.textLabel!.text = "Number of records: " + " " + glucoseMeasurementCount.description
                cell.detailTextLabel!.text = ""
                cell.accessoryType = .none
            case .glucoseMeterRecords:
                let measurement = Array(glucoseMeasurements)[indexPath.row]
                let mmolString = String(describing: measurement.toMMOL()!.truncateMeasurement())
                let contextWillFollow: Bool = (measurement.contextInformationFollows)
                
                cell.textLabel!.text = "Record: \(measurement.sequenceNumber)\nGlucose (kg/L): \(measurement.glucoseConcentration) \(measurement.unit.description)\nGlucose (mmol/L): \(mmolString) mmol/L\nContext: \(contextWillFollow.description)\n\nDate: \(String(describing: measurement.dateTime!.description))"
                
                if let fhirID = measurement.fhirID {
                    cell.detailTextLabel!.text = "FHIR ID: \(fhirID)"
                    cell.accessoryView = nil
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.detailTextLabel!.text = "Observation: Tap to upload"
                    cell.accessoryType = .none
                }
            default:
                break
        }
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionType = Section(rawValue: section)
        return sectionType?.description() ?? "none"
    }

    // MARK: table delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)! as UITableViewCell
        
        guard let section = Section(rawValue:indexPath.section) else {
            fatalError("invalid section")
        }
        
        switch section {
            case .patient:
                if (BGMFhir.BGMFhirInstance.patient?.id) != nil {
                    performSegue(withIdentifier: "segueToPatient", sender: self)
                } else {
                    cell.accessoryView = self.createActivityView()
                    BGMFhir.BGMFhirInstance.createPatient { (patient, error) -> Void in
                        if error == nil {
                            print("patient created with id: \(patient.id!)")
                        }
                        self.refresh()
                    }
                }
            case .glucoseMeterDevice:
                if (BGMFhir.BGMFhirInstance.device?.id) != nil {
                    performSegue(withIdentifier: "segueToDevice", sender: self)
                } else {
                    cell.accessoryView = self.createActivityView()
                    BGMFhir.BGMFhirInstance.createDevice { (device, error) -> Void in
                        if error == nil {
                            print("device created with id: \(device.id!)")
                            BGMFhir.BGMFhirInstance.createDeviceComponent { (error) -> Void in
                                if error == nil {
                                    print("device component created with id: \(String(describing: BGMFhir.BGMFhirInstance.deviceComponent!.id!))")
                                    BGMFhir.BGMFhirInstance.createSpecimen()
                                }
                            
                            }
                        }
                        self.refresh()
                    }
                }
            case .glucoseMeterRecords:
                if glucoseMeasurements[indexPath.row].existsOnFHIR == true {
                    selectedGlucoseMeasurement = glucoseMeasurements[indexPath.row]
                    performSegue(withIdentifier: "segueToObservation", sender: self)
                } else {
                    if BGMFhir.BGMFhirInstance.patient == nil || BGMFhir.BGMFhirInstance.device == nil {
                        self.showAlert(title: "Patient and/or Device not uploaded", message: "Upload patient and/or device first")
                    } else {
                        cell.accessoryView = self.createActivityView()
                       
                        BGMFhir.BGMFhirInstance.uploadSingleMeasurement(measurement: glucoseMeasurements[indexPath.row]) { (observation, error) -> Void in
                            if let error = error {
                                print("error uploading observation: \(error)")
                            }
                            self.refresh()
                        }
                    }
                }
            default:
                break
        }
    }
    
    func getMeasurementFromArray(sequenceNumber: UInt16) -> GlucoseMeasurement? {
        for measurement: GlucoseMeasurement in glucoseMeasurements {
            if measurement.sequenceNumber == sequenceNumber {
                return measurement
            }
        }
        return nil
    }

    //MARK
    func error(error: Error) {
        print("error: ")
        print(error)
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
            action.isEnabled = true
        })
        self.present(alert, animated: true)
    }
    
    @IBAction func uploadObservationsButtonAction(_ sender: Any) {
        if BGMFhir.BGMFhirInstance.patient == nil || BGMFhir.BGMFhirInstance.device == nil {
            self.showAlert(title: "Patient and/or device not uploaded", message: "Upload patient and/or device first")
            return
        }
        
        BGMFhir.BGMFhirInstance.uploadObservationBundle(measurements: self.glucoseMeasurements) { (bundle, error) -> Void in
            if let error = error {
                print("error uploading bundle: \(error)")
            }
            self.refresh()
        }
    }
}

extension String {
  func stringByAddingPercentEncodingForRFC3986() -> String? {
        let allowedCharacters = NSCharacterSet.urlFragmentAllowed
        let encodedString = self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    
        return encodedString
    }
}
