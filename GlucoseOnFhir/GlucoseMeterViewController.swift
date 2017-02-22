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
    private var glucose: Glucose!
    let cellIdentifier = "GlucoseMeterCellIdentifier"
    var glucoseMeterConnected: Bool! = false
    var glucoseMeter: CBPeripheral!
    var glucoseFeatures: GlucoseFeatures!
    var glucoseMeasurementCount: UInt16 = 0
    //var glucoseMeasurements: Array<GlucoseMeasurement> = Array<GlucoseMeasurement>()
    //var glucoseMeasurementContexts: Array<GlucoseMeasurementContext> = Array<GlucoseMeasurementContext>()
    var glucoseMeasurements: [GlucoseMeasurement] = [GlucoseMeasurement]()
    var glucoseMeasurementContexts: [GlucoseMeasurementContext] = [GlucoseMeasurementContext]()
    
    var selectedGlucoseMeasurement: GlucoseMeasurement!
    var selectedGlucoseMeasurementContext: GlucoseMeasurementContext!
    
    let givenName = "Lisa"
    let familyName = "Simpson"
    
    public var patient: Patient?
    public var device: Device?
    //public var observations: Array<Observation> = Array<Observation>()
    public var observations: [Observation] = [Observation]()
    
    struct LogMessage {
        let date: Date
        let text: String
    }
    var log: [LogMessage] = []
    
    enum Section: Int {
        case patient, glucoseMeterDevice, glucoseMeterRecordCount, glucoseMeterRecords, log, count
        
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
            case .log:
                return "Log"
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
            case .log:
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
        
        glucose = Glucose(peripheral: glucoseMeter)
        glucose.glucoseDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.estimatedRowHeight = 70
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        
        if glucoseMeterConnected == true {
            glucose.disconnectGlucoseMeter()
        }
    }
    
    // MARK: GlucoseProtocol
    func glucoseMeterConnected(meter: CBPeripheral) {
        print("GlucoseMeterViewController#glucoseMeterConnected")
        logEvent(event: "meter connected")
        glucoseMeterConnected = true
    }
    
    public func glucoseMeterDisconnected(meter: CBPeripheral) {
        print("GlucoseMeterViewController#glucoseMeterDisconnected")
        logEvent(event: "meter disconnected")
        glucoseMeterConnected = false
    }
    
    func numberOfStoredRecords(number: UInt16) {
        print("GlucoseMeterViewController#numberOfStoredRecords - \(number)")
        logEvent(event: "meter number of records: \(number)")
        glucoseMeasurementCount = number
    
        //download records from meter, eg. records 213 - 216
        glucose.downloadRecordsWithRange(from: 213, to: 216)
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
        glucoseMeasurementContexts.append(measurementContext)
    }
    
    func glucoseFeatures(features: GlucoseFeatures) {
        glucoseFeatures = features
    }
    
    public func glucoseMeterDidTransferMeasurements(error: NSError?) {
        print("glucoseMeterDidTransferMeasurements")
        
        DispatchQueue.once(executeToken: "glucoseOnFhir.glucoseMeterDidTransferMeasurements.runOnce") {
            self.searchForPatient(given: self.givenName, family: self.familyName) { (bundle, error) -> Void in
                if let error = error {
                    print("error searching for patient: \(error)")
                }

                if bundle?.entry != nil {
                    self.searchForObservations()
                }
            }
            self.searchForDevice { (bundle, error) -> Void in }
        }
    }
    
    func searchForObservations() {
        for measurement in self.glucoseMeasurements {
            self.searchForObservation(measurement: measurement) { (bundle, error) -> Void in
                if let error = error {
                    print("error searching for observation: \(error)")
                }
                
                if bundle?.entry == nil {
                    print("measurement \(measurement.sequenceNumber) not found")
                    self.logEvent(event: "measurement \(measurement.sequenceNumber) not found")
                    measurement.existsOnFHIR = false
                } else {
                    print("measurement \(measurement.sequenceNumber) found")
                    self.logEvent(event: "measurement \(measurement.sequenceNumber) found")
                    measurement.existsOnFHIR = true
                    measurement.fhirID = bundle?.entry?.first?.resource?.id
                    
                    if bundle?.entry != nil {
                        let observations = bundle?.entry?
                            .filter { return $0.resource is Observation }
                            .map { return $0.resource as! Observation }
                        
                        self.observations.append((observations?.first)!)
                        print("observations count: \(self.observations.count)")
                    }
                }
                self.refresh()
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
            PatientViewVC.patient = self.patient
        }
        if segue.identifier == "segueToDevice" {
            let DeviceViewVC =  segue.destination as! DeviceViewController
            DeviceViewVC.device = self.device
        }
        if segue.identifier == "segueToObservation" {
            let ObservationViewVC =  segue.destination as! ObservationViewController
            ObservationViewVC.observation = observationForMeasurement(measurement: selectedGlucoseMeasurement)
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
            case .log:
                return log.count
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
                
                if self.patient != nil {
                    cell.detailTextLabel!.text = "Patient FHIR ID: " + (self.patient?.id)!
                    cell.accessoryView = nil
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.detailTextLabel!.text = "Patient: Tap to upload"
                }
            case .glucoseMeterDevice:
                if let manufacturer = glucose.manufacturerName {
                    cell.textLabel!.text = "Manufacturer: \(manufacturer)"
                }
                if let modelNumber = glucose.modelNumber {
                    cell.textLabel?.text?.append("\nModel: \(modelNumber)")
                }
                if let serialNumber = glucose.serialNumber {
                    cell.textLabel?.text?.append("\nSerial: \(serialNumber)")
                }
                if self.device != nil {
                    cell.detailTextLabel!.text = "Device FHIR ID: " + (self.device?.id)!
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
                let mmolString = String(describing: self.truncateMeasurement(measurementValue: measurement.toMMOL()!))
                let contextWillFollow: Bool = (measurement.contextInformationFollows)
                
                cell.textLabel!.text = "Record: \(measurement.sequenceNumber)\nGlucose (kg/L): \(measurement.glucoseConcentration) \(measurement.unit.description)\nGlucose (mmol/L): \(mmolString) mmol/L\nContext: \(contextWillFollow.description)\n\nDate: \(measurement.dateTime!.description)"
                
                print("measurement existsOnFhir?: \(measurement.existsOnFHIR)")
                
                if let fhirID = measurement.fhirID {
                    cell.detailTextLabel!.text = "FHIR ID: \(fhirID)"
                    cell.accessoryView = nil
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.detailTextLabel!.text = "Observation: Tap to upload"
                    cell.accessoryType = .none
                }
            case .log:
                cell.textLabel!.text = log[indexPath.row].text
                cell.detailTextLabel!.text = log[indexPath.row].date.description
                cell.accessoryType = .none
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
                if (self.patient?.id) != nil {
                    performSegue(withIdentifier: "segueToPatient", sender: self)
                } else {
                    cell.accessoryView = self.createActivityView()
                    self.createPatient { (patient, error) -> Void in
                        if error == nil {
                            print("patient created with id: \(patient.id!)")
                            self.logEvent(event: "patient created with id: \(patient.id!)")
                        }
                    }
                }
            case .glucoseMeterDevice:
                if (self.device?.id) != nil {
                    performSegue(withIdentifier: "segueToDevice", sender: self)
                } else {
                    cell.accessoryView = self.createActivityView()
                    self.createDevice { (device, error) -> Void in
                        if error == nil {
                            print("device created with id: \(device.id!)")
                            self.logEvent(event: "device created with id: \(device.id!)")
                        }
                    }
                }
            case .glucoseMeterRecords:
                if glucoseMeasurements[indexPath.row].existsOnFHIR == true {
                    selectedGlucoseMeasurement = glucoseMeasurements[indexPath.row]
                    performSegue(withIdentifier: "segueToObservation", sender: self)
                } else {
                    if self.patient == nil || self.device == nil {
                        self.showAlert(title: "Patient and/or Device not uploaded", message: "Upload patient and/or device first")
                    } else {
                        cell.accessoryView = self.createActivityView()
                        self.uploadSingleMeasurement(measurement: glucoseMeasurements[indexPath.row])
                    }
                }
            default:
                break
        }
    }
    
    func getContextFromArray(sequenceNumber: UInt16) -> GlucoseMeasurementContext? {
        for context: GlucoseMeasurementContext in glucoseMeasurementContexts {
            if context.sequenceNumber == sequenceNumber {
                return context
            }
        }
        return nil
    }
    
    func getMeasurementFromArray(sequenceNumber: UInt16) -> GlucoseMeasurement? {
        for measurement: GlucoseMeasurement in glucoseMeasurements {
            if measurement.sequenceNumber == sequenceNumber {
                return measurement
            }
        }
        return nil
    }

    func searchForPatient(given: String, family: String, callback: @escaping FHIRSearchBundleErrorCallback) {
        print("GlucoseMeterViewController: searchForPatient")
        let searchDict: [String:Any] = [
            "given": given,
            "family": family
        ]
        
        logEvent(event: "searching for patient \(given) \(family)")
        
        FHIR.fhirInstance.searchForPatient(searchParameters: searchDict) { (bundle, error) -> Void in
            if let error = error {
                print("error searching for patient: \(error)")
            }
            
            if bundle?.entry == nil {
                self.logEvent(event: "patient not found")
            } else {
                self.logEvent(event: "patient found")
                
                if bundle?.entry != nil {
                    let patients = bundle?.entry?
                        .filter { return $0.resource is Patient }
                        .map { return $0.resource as! Patient }
                    
                    self.patient = patients?[0]
                }
            }
            callback(bundle, error)
        }
    }
    
    func createPatient(callback: @escaping (_ patient: Patient, _ error: Error?) -> Void) {
        let patientName = HumanName(json: nil)
        patientName.family = [self.familyName]
        patientName.given = [self.givenName]
        patientName.use = "official"
        
        let patientTelecom = ContactPoint(json: nil)
        patientTelecom.use = "work"
        patientTelecom.value = "4163404800"
        patientTelecom.system = "phone"
        
        let patientAddress = Address(json: nil)
        patientAddress.city = "Toronto"
        patientAddress.country = "Canada"
        patientAddress.postalCode = "M5G2C4"
        patientAddress.line = ["585 University Ave"]
        
        let patientBirthDate = FHIRDate(string: DateTime.now.date.description)
        
        let patient = Patient(json: nil)
        patient.active = true
        patient.name = [patientName]
        patient.telecom = [patientTelecom]
        patient.address = [patientAddress]
        patient.birthDate = patientBirthDate
        
        FHIR.fhirInstance.createPatient(patient: patient) { patient, error in
            if let error = error {
                print("error creating patient: \(error)")
            } else {
                self.patient = patient
            }
            callback(patient, error)
        }
    }
    
    func createDevice(callback: @escaping (_ device: Device, _ error: Error?) -> Void) {
        let modelNumber = glucose.modelNumber!.replacingOccurrences(of: "\0", with: "")
        let manufacturer = glucose.manufacturerName!.replacingOccurrences(of: "\0", with: "")
        let serialNumber = glucose.serialNumber!.replacingOccurrences(of: "\0", with: "")
        
        let deviceCoding = Coding(json: nil)
        deviceCoding.code = "337414009"
        deviceCoding.system = URL(string: "http://snomed.info/sct")
        deviceCoding.display = "Blood glucose meters (physical object)"
        
        let deviceType = CodeableConcept(json: nil)
        deviceType.coding = [deviceCoding]
        deviceType.text = "Glucose Meter"
        
        let deviceIdentifierTypeCoding = Coding(json: nil)
        deviceIdentifierTypeCoding.system = URL(string: "http://hl7.org/fhir/identifier-type")
        deviceIdentifierTypeCoding.code = "SNO"
        
        let deviceIdentifierType = CodeableConcept(json: nil)
        deviceIdentifierType.coding = [deviceIdentifierTypeCoding]
        
        let deviceIdentifier = Identifier(json: nil)
        deviceIdentifier.value = serialNumber
        deviceIdentifier.type = deviceIdentifierType
        deviceIdentifier.system = URL(string: "http://roche.com/accucheck/serial")
        
        let device = Device(json: nil)
        device.status = "available"
        device.manufacturer = manufacturer
        device.model = modelNumber
        device.type = deviceType
        device.identifier = [deviceIdentifier]
        
        FHIR.fhirInstance.createDevice(device: device) { device, error in
            if let error = error {
                print("error creating device: \(error)")
            } else {
                self.device = device
            }
            callback(device, error)
        }
    }
    
    func searchForDevice(callback: @escaping FHIRSearchBundleErrorCallback) {
        let modelNumber = glucose.modelNumber!.replacingOccurrences(of: "\0", with: "")
        let manufacturer = glucose.manufacturerName!.replacingOccurrences(of: "\0", with: "")
        
        let searchDict: [String:Any] = [
            "model": modelNumber,
            "manufacturer": manufacturer,
            "identifier": glucose.serialNumber!
        ]
        
        logEvent(event: "searching for device \(manufacturer) \(modelNumber)")
        
        FHIR.fhirInstance.searchForDevice(searchParameters: searchDict) { (bundle, error) -> Void in
            if let error = error {
                print("error searching for device: \(error)")
            }

            if bundle?.entry == nil {
                self.logEvent(event: "device not found")
            } else {
                self.logEvent(event: "device found")
                
                if bundle?.entry != nil {
                    let devices = bundle?.entry?
                        .filter { return $0.resource is Device }
                        .map { return $0.resource as! Device }
                    
                    self.device = devices?[0]
                }
            }
            callback(bundle, error)
        }
    }
    
    func measurementToObservation(measurement: GlucoseMeasurement) -> Observation {
        var codingArray = [Coding]()
        let coding = Coding(json: nil)
        coding.system = URL(string: "http://loinc.org")
        coding.code = "15074-8"
        coding.display = "Glucose [Moles/volume] in Blood"
        codingArray.append(coding)
        
        let codableConcept = CodeableConcept(json: nil)
        codableConcept.coding = codingArray as [Coding]
        
        let deviceReference = Reference(json: nil)
        deviceReference.reference = "Device/" + (self.device?.id)!
        
        let subjectReference = Reference(json: nil)
        subjectReference.reference = "Patient/" + (self.patient?.id)!
        
        var performerArray = [Reference]()
        let performerReference = Reference(json: nil)
        performerReference.reference = "Patient/" + (self.patient?.id)!
        performerArray.append(performerReference)
        
        let measurementNumber = NSDecimalNumber(value: self.truncateMeasurement(measurementValue: measurement.toMMOL()!))
        let decimalRoundingBehaviour = NSDecimalNumberHandler(roundingMode:.plain,
                                               scale: 2, raiseOnExactness: false,
                                               raiseOnOverflow: false, raiseOnUnderflow:
                                               false, raiseOnDivideByZero: false)
        
        let quantity = Quantity.init(json: nil)
        quantity.value = measurementNumber.rounding(accordingToBehavior: decimalRoundingBehaviour)
        quantity.code = "mmol/L"
        quantity.system = URL(string: "http://unitsofmeasure.org")
        quantity.unit = "mmol/L"
        
        let effectivePeriod = Period(json: nil)
        effectivePeriod.start = DateTime(string: (measurement.dateTime?.iso8601)!)
        effectivePeriod.end = DateTime(string: (measurement.dateTime?.iso8601)!)
        
        let observation = Observation.init(json: nil)
        observation.status = "final"
        observation.code = codableConcept
        observation.valueQuantity = quantity
        observation.effectivePeriod = effectivePeriod
        observation.device = deviceReference
        observation.subject = subjectReference
        observation.performer = performerArray
        
        if measurement.contextInformationFollows {
            let mealContext: GlucoseMeasurementContext! = self.getContextFromArray(sequenceNumber: measurement.sequenceNumber)
            
            var observationExtensionArray = [Extension]()
            let bluetoothGlucoseMeasurementContextURL: String = "https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.glucose_measurement_context.xml"
            
            if mealContext != nil {
                // Carbohydrate ID
                if mealContext?.carbohydrateID?.description != nil {
                    let extensionElementCoding = Coding(json: nil)
                    extensionElementCoding.system = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = mealContext?.carbohydrateID?.rawValue.description
                    extensionElementCoding.display = mealContext?.carbohydrateID?.description
                
                    let extensionElement = Extension(json: nil)
                    extensionElement.url = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                
                    observationExtensionArray.append(extensionElement)
                }
                
                // Carbohydrate Weight
                if mealContext?.carbohydrateWeight?.description != nil {
                    let extensionElementCoding = Coding(json: nil)
                    extensionElementCoding.system = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = mealContext?.carbohydrateWeight!.description
                    extensionElementCoding.display = mealContext?.carbohydrateWeight!.description
                    
                    let extensionElement = Extension(json: nil)
                    extensionElement.url = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Meal
                if mealContext?.meal?.description != nil {
                    let extensionElementCoding = Coding(json: nil)
                    extensionElementCoding.system = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = mealContext?.meal?.rawValue.description
                    extensionElementCoding.display = mealContext?.meal?.description
                    
                    let extensionElement = Extension(json: nil)
                    extensionElement.url = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Tester
                if mealContext?.tester?.description != nil {
                    let extensionElementCoding = Coding(json: nil)
                    extensionElementCoding.system = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = mealContext?.tester
                    extensionElementCoding.display = mealContext?.tester?.description
                    
                    let extensionElement = Extension(json: nil)
                    extensionElement.url = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Health
                if mealContext?.health?.description != nil {
                    let extensionElementCoding = Coding(json: nil)
                    extensionElementCoding.system = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = mealContext?.health
                    extensionElementCoding.display = mealContext?.health?.description
                    
                    let extensionElement = Extension(json: nil)
                    extensionElement.url = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Exercise Duration
                if mealContext?.exerciseDuration?.description != nil {
                    let extensionElementCoding = Coding(json: nil)
                    extensionElementCoding.system = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = mealContext?.exerciseDuration?.description
                    extensionElementCoding.display = mealContext?.exerciseDuration?.description
                    
                    let extensionElement = Extension(json: nil)
                    extensionElement.url = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Exercise Intensity
                if mealContext?.exerciseIntensity?.description != nil {
                    let extensionElementCoding = Coding(json: nil)
                    extensionElementCoding.system = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = mealContext?.exerciseIntensity?.description
                    extensionElementCoding.display = mealContext?.exerciseIntensity?.description
                    
                    let extensionElement = Extension(json: nil)
                    extensionElement.url = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Medication ID
                if mealContext?.medicationID?.description != nil {
                    let extensionElementCoding = Coding(json: nil)
                    extensionElementCoding.system = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = mealContext?.medicationID?.description
                    extensionElementCoding.display = mealContext?.medicationID?.description
                    
                    let extensionElement = Extension(json: nil)
                    extensionElement.url = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Medication
                if mealContext?.medication?.description != nil {
                    let extensionElementCoding = Coding(json: nil)
                    extensionElementCoding.system = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = mealContext?.medication!.description
                    extensionElementCoding.display = mealContext?.medication!.description
                    
                    let extensionElement = Extension(json: nil)
                    extensionElement.url = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }

                // hbA1c
                if mealContext?.hbA1c?.description != nil {
                    let extensionElementCoding = Coding(json: nil)
                    extensionElementCoding.system = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = mealContext?.hbA1c?.description
                    extensionElementCoding.display = mealContext?.hbA1c?.description
                    
                    let extensionElement = Extension(json: nil)
                    extensionElement.url = URL(string: bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
            }
            observation.extension_fhir = observationExtensionArray
        }
        return observation
    }
    
    func truncateMeasurement(measurementValue: Float) -> Float {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = NumberFormatter.RoundingMode.down
        let truncatedValue = formatter.string(from: NSNumber(value: measurementValue))
        
        return Float(truncatedValue!)!
    }
    
    func searchForObservation(measurement: GlucoseMeasurement, callback: @escaping FHIRSearchBundleErrorCallback) {
        let truncatedMeasurement = String(describing: self.truncateMeasurement(measurementValue: measurement.toMMOL()!))
        
        let searchDict: [String: Any] = [
            "subject": (self.patient?.id)! as String,
            "date": measurement.dateTime?.iso8601 as Any,
            "code": "http://loinc.org%7C15074-8",
            "value-quantity": (truncatedMeasurement as String) + "%7Chttp://unitsofmeasure.org%7Cmmol/L"
        ]
        
        self.logEvent(event: "searching for measurement \(measurement.sequenceNumber)")
        
        //FHIR.sharedInstance.searchForObservation(searchParameters: searchDict) { (bundle, error) -> Void in
        FHIR.fhirInstance.searchForObservation(searchParameters: searchDict) { bundle, error in
            if let error = error {
                print("error searching for observation: \(error)")
            }
            callback(bundle, error)
        }
    }
    
    func uploadSingleMeasurement(measurement: GlucoseMeasurement) {
        if measurement.existsOnFHIR == false {
            FHIR.fhirInstance.createObservation(observation: self.measurementToObservation(measurement: measurement)) { (observation, error) -> Void in
                guard error == nil else {
                    print("error creating observation: \(error)")
                    return
                }
                
                print("observation uploaded with id: \(observation.id!)")
                self.logEvent(event: "observation uploaded with id: \(observation.id!)")
                measurement.existsOnFHIR = true
                measurement.fhirID = observation.id!
                self.observations.append(observation)
                
                self.refresh()
            }
        }
    }
    
    func observationForMeasurement(measurement: GlucoseMeasurement) -> Observation {
        for observation in observations {
            if observation.id == measurement.fhirID {
                return observation
            }
        }
        return Observation(json: nil)
    }
    
    //MARK
    func error(error: Error) {
        print("error: ")
        print(error)
    }
    
    func logEvent(event: String) {
        let logMessage = LogMessage(date: Date(), text: event)
        log.append(logMessage)
        self.refresh()
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
            action.isEnabled = true
        })
        self.present(alert, animated: true)
    }
    
    
    @IBAction func uploadObservationsButtonAction(_ sender: Any) {
        var observations: [Observation] = []
        
        if self.patient == nil || self.device == nil {
            self.showAlert(title: "Patient and/or Device not uploaded", message: "Upload patient and/or device first")
            return
        }
        
        for measurement in glucoseMeasurements {
            if measurement.existsOnFHIR == false {
                observations.append(self.measurementToObservation(measurement: measurement))
            }
        }
        
        if observations.count == 0 {
            self.showAlert(title: "Nothing to upload", message: "")
            return
        }
        
        FHIR.fhirInstance.createObservationBundle(type: "batch", observations: observations) { (bundle, error) -> Void in
            guard error == nil else {
                print("error creating observations: \(error)")
                return
            }
            
            if let count = bundle?.entry?.count {
                //iterate through the batch response entries
                for i in 1...count-1 {
                    if bundle?.entry?[i].response?.status == "201 Created" {
                        let components = bundle?.entry?[i].response?.location?.absoluteString.components(separatedBy: "/")
                        
                        for measurement in self.glucoseMeasurements {
                            if measurement.existsOnFHIR == false {
                                measurement.existsOnFHIR = true
                                measurement.fhirID = components![1]
                                break
                            }
                        }
                        
                        observations[i-1].id = components![1]
                        self.observations.append(observations[i-1])
                        print("observation uploaded with ID \(components![1])")
                        self.logEvent(event: "observation uploaded with ID \(components![1])")
                    } else {
                        self.logEvent(event: "error creating observation")
                        print("error creating observation")
                    }
                }
            }
        }
    }
}
