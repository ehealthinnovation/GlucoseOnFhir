//
//  GlucoseMeterViewController.swift
//  CCBluetooth
//
//  Created by Kevin Tallevi on 7/8/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

//TO-DO: only add observations to the bundle that do not exist on the FHIR server

import Foundation
import UIKit
import CoreBluetooth
import CCGlucose
import CCToolbox
import SwiftSpinner
import SMART

class GlucoseMeterViewController: UITableViewController, GlucoseProtocol, FHIRProtocol {
    private var glucose : Glucose!
    let cellIdentifier = "GlucoseMeterCellIdentifier"
    var glucoseFeatures: GlucoseFeatures!
    var glucoseMeasurementCount: UInt16 = 0
    var glucoseMeasurements: Array<GlucoseMeasurement> = Array<GlucoseMeasurement>()
    var glucoseMeasurementContexts: Array<GlucoseMeasurementContext> = Array<GlucoseMeasurementContext>()
    var selectedGlucoseMeasurement: GlucoseMeasurement!
    var selectedGlucoseMeasurementContext: GlucoseMeasurementContext!
    var selectedMeter: CBPeripheral!
    var meterConnected: Bool!
    private var fhir : FHIR!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("GlucoseMeterViewController#viewDidLoad")
        print("selectedMeter: \(selectedMeter)")
        meterConnected = false
        
        glucose = Glucose(peripheral: selectedMeter)
        glucose.glucoseDelegate = self
        
        fhir = FHIR()
        fhir.FHIRDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        SwiftSpinner.show("Connecting to meter...", animated: true)
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        
        if(meterConnected == true) {
           glucose.disconnectGlucoseMeter()
        }
    }
    
    // MARK: - GlucoseProtocol
    func glucoseMeterConnected(meter: CBPeripheral) {
        SwiftSpinner.show("Downloading records", animated: true)
        print("GlucoseMeterViewController#glucoseMeterConnected")
        meterConnected = true
    }
    
    public func glucoseMeterDisconnected(meter: CBPeripheral) {
        print("GlucoseMeterViewController#glucoseMeterDisconnected")
        meterConnected = false
    }
    
    func numberOfStoredRecords(number: UInt16) {
        print("GlucoseMeterViewController#numberOfStoredRecords - \(number)")
        glucoseMeasurementCount = number
        self.refreshTable()
        
        glucose.downloadLastRecord()
    }
    
    func glucoseMeasurement(measurement:GlucoseMeasurement) {
        glucoseMeasurements.append(measurement)
        
        self.refreshTable()
    }
    
    func glucoseMeasurementContext(measurementContext:GlucoseMeasurementContext) {
        glucoseMeasurementContexts.append(measurementContext)
    }
    
    func glucoseFeatures(features:GlucoseFeatures) {
        glucoseFeatures = features
        
        self.refreshTable()
    }
    
    public func glucoseMeterDidTransferMeasurements(error: NSError?) {
        SwiftSpinner.show(duration: 1.5, title: "Download Complete", animated: false)
        SwiftSpinner.show("Connecting to FHIR", animated: true)
        
        self.searchForPatient()
    }
    
    public func glucoseError(error: NSError) {
        print("glucoseError")
    }
    
    // MARK: - Storyboard
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0:
                if(glucoseFeatures != nil) {
                    return 11
                } else {
                    return 0
                }
            case 1:
                if(glucoseMeasurementCount > 0) {
                    return 1
                } else {
                    return 0
                }
            case 2:
                return glucoseMeasurements.count
            default:
                return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
        
        switch indexPath.section {
            case 0:
                if(glucoseFeatures != nil) {
                    switch indexPath.row {
                        case 0:
                            cell.textLabel!.text = glucoseFeatures.lowBatterySupported?.description
                            cell.detailTextLabel!.text = "Low Battery Supported"
                        case 1:
                            cell.textLabel!.text = glucoseFeatures.sensorMalfunctionDetectionSupported?.description
                            cell.detailTextLabel!.text = "Sensor Malfunction Detection Supported"
                        case 2:
                            cell.textLabel!.text = glucoseFeatures.sensorSampleSizeSupported?.description
                            cell.detailTextLabel!.text = "Sensor Sample Size Supported"
                        case 3:
                            cell.textLabel!.text = glucoseFeatures.sensorStripInsertionErrorDetectionSupported?.description
                            cell.detailTextLabel!.text = "Sensor Strip Insertion Error Detection Supported"
                        case 4:
                            cell.textLabel!.text = glucoseFeatures.sensorStripTypeErrorDetectionSupported?.description
                            cell.detailTextLabel!.text = "Sensor Strip Type Error Detection Supported"
                        case 5:
                            cell.textLabel!.text = glucoseFeatures.sensorResultHighLowDetectionSupported?.description
                            cell.detailTextLabel!.text = "Sensor Result High Low Detection Supported"
                        case 6:
                            cell.textLabel!.text = glucoseFeatures.sensorTemperatureHighLowDetectionSupported?.description
                            cell.detailTextLabel!.text = "Sensor Temperature High Low Detection Supported"
                        case 7:
                            cell.textLabel!.text = glucoseFeatures.sensorReadInterruptDetectionSupported?.description
                            cell.detailTextLabel!.text = "Sensor Read Interrupt Detection Supported"
                        case 8:
                            cell.textLabel!.text = glucoseFeatures.generalDeviceFaultSupported?.description
                            cell.detailTextLabel!.text = "General Device Fault Supported"
                        case 9:
                            cell.textLabel!.text = glucoseFeatures.timeFaultSupported?.description
                            cell.detailTextLabel!.text = "Time Fault Supported"
                        case 10:
                            cell.textLabel!.text = glucoseFeatures.multipleBondSupported?.description
                            cell.detailTextLabel!.text = "MultipleBond Supported"
                        default:
                            cell.textLabel!.text = ""
                            cell.detailTextLabel!.text = ""
                    }
                }
            case 1:
                if (glucoseMeasurementCount > 0) {
                    cell.textLabel!.text = "Number of records: " + " " + glucoseMeasurementCount.description
                    cell.detailTextLabel!.text = ""
                }
            case 2:
                let measurement = Array(glucoseMeasurements)[indexPath.row]
                let mmolString = String(describing: self.truncateMeasurement(measurementValue: measurement.toMMOL()!))
                let contextWillFollow : Bool = (measurement.contextInformationFollows)
                
                cell.textLabel!.text = "[\(contextWillFollow.description)] (\(measurement.sequenceNumber)) \(measurement.glucoseConcentration) \(measurement.unit.description) (\(mmolString) mmol/L)"
                
                cell.detailTextLabel!.text = measurement.dateTime?.description
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
        }
        
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return "Glucose Meter Features"
            case 1:
                return "Glucose Record Count"
            case 2:
                return "Glucose Records"
            default:
                return ""
        }
    }

    //MARK: - table delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if(indexPath.section == 2) {
            selectedGlucoseMeasurement = Array(glucoseMeasurements)[indexPath.row]
            performSegue(withIdentifier: "segueToMeasurementDetails", sender: self)
        }
    }
    
    // MARK: -
    func refreshTable() {
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    func getContextFromArray(sequenceNumber:UInt16) -> GlucoseMeasurementContext? {
        for context: GlucoseMeasurementContext in glucoseMeasurementContexts {
            if(context.sequenceNumber == sequenceNumber) {
                print("found context")
                return context
            }
        }
    
        return nil
    }
    
    func getMeasurementFromArray(sequenceNumber:UInt16) -> GlucoseMeasurement? {
        for measurement: GlucoseMeasurement in glucoseMeasurements {
            if(measurement.sequenceNumber == sequenceNumber) {
                return measurement
            }
        }
        return nil
    }

    
    //MARK
    func searchForPatient() {
            let searchDict:[String:Any] = [
            "given":"Lisa",
            "family":"Simpson"
        ]
        
        fhir.searchForPatient(searchParameters:searchDict)
    }

    func createPatient() {
        let patientName = HumanName(json: nil)
        patientName.family = ["Simpson"]
        patientName.given = ["Lisa"]
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
        
        print(patient.asJSON())
        
        fhir.createPatient(patient: patient)
    }
    
    func createDevice() {
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
        
        fhir.createDevice(device: device)
    }
    
    func searchForDevice() {
        let modelNumber = glucose.modelNumber!.replacingOccurrences(of: "\0", with: "")
        let manufacturer = glucose.manufacturerName!.replacingOccurrences(of: "\0", with: "")
        
        let paramatersDict:[String:Any] = [
            "model":modelNumber,
            "manufacturer":manufacturer,
            "identifier": glucose.serialNumber!
        ]
        
        fhir.searchForDevice(searchParameters: paramatersDict)
    }
    
    func measurementToObservation(measurement:GlucoseMeasurement) -> Observation {
        var codingArray = [Coding]()
        let coding = Coding(json: nil)
        coding.system = URL(string: "http://loinc.org")
        coding.code = "15074-8"
        coding.display = "Glucose [Moles/volume] in Blood"
        codingArray.append(coding)
        
        let codableConcept = CodeableConcept(json: nil)
        codableConcept.coding = codingArray as [Coding]
        
        let deviceReference = Reference(json: nil)
        deviceReference.reference = "Device/" + (fhir.device?.id)!
        
        let subjectReference = Reference(json: nil)
        subjectReference.reference = "Patient/" + (fhir.patient?.id)!
        
        var performerArray = [Reference]()
        let performerReference = Reference(json: nil)
        performerReference.reference = "Patient/" + (fhir.patient?.id)!
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
        
        if(measurement.contextInformationFollows) {
            let mealContext: GlucoseMeasurementContext! = self.getContextFromArray(sequenceNumber: measurement.sequenceNumber)
            
            var observationExtensionArray = [Extension]()
            let bluetoothGlucoseMeasurementContextURL:String = "https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.glucose_measurement_context.xml"
            
            if(mealContext != nil) {
                // Carbohydrate ID
                if(mealContext?.carbohydrateID?.description != nil) {
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
                if(mealContext?.carbohydrateWeight?.description != nil) {
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
                if(mealContext?.meal?.description != nil) {
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
                if(mealContext?.tester?.description != nil) {
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
                if(mealContext?.health?.description != nil) {
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
                if(mealContext?.exerciseDuration?.description != nil) {
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
                if(mealContext?.exerciseIntensity?.description != nil) {
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
                if(mealContext?.medicationID?.description != nil) {
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
                if(mealContext?.medication?.description != nil) {
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
                if(mealContext?.hbA1c?.description != nil) {
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
            
            print(observation.asJSON())
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
    
    func searchForObservation(measurement: GlucoseMeasurement) {
        let truncatedMeasurement = String(describing: self.truncateMeasurement(measurementValue: measurement.toMMOL()!))
        
        let searchDict:[String:Any] = [
            "subject": (fhir.patient?.id)! as String,
            "date": measurement.dateTime?.iso8601 as Any,
            "code": "http://loinc.org%7C15074-8",
            "value-quantity": (truncatedMeasurement as String) + "%7Chttp://unitsofmeasure.org%7Cmmol/L"
        ]
        
        print(searchDict)
        
        fhir.searchForObservation(searchParameters: searchDict)
    }
    
    func uploadMeasurements() {
        if(glucoseMeasurements.count > 1) {
            SwiftSpinner.show("Uploading bundle", animated: true)
            
            var observationArray: [Observation] = []
            for measurement in glucoseMeasurements {
                observationArray.append(self.measurementToObservation(measurement: measurement))
            }
            
            fhir.createObservationBundle(observations: observationArray)
        } else {
            SwiftSpinner.show("Uploading observation", animated: true)
            fhir.createObservation(observation: self.measurementToObservation(measurement: glucoseMeasurements[0]))
        }
    }
    
    //MARK
    func error(error:Error) {
        print("error: ")
        print(error)
    }
    
    func patientNotFound() {
        print("patientNotFound")
        //SwiftSpinner.show("Patient not found", animated: true)
        self.createPatient()
    }
    
    func patientFound(patientID:String) {
        print("patient found, ID: \(patientID)")
        //SwiftSpinner.show("Patient found", animated: true)
        //self.searchForObservation(measurement: glucoseMeasurements[0])
        self.searchForDevice()
    }
    
    func patientCreated(patientID:String) {
        print("patient created, ID: \(patientID)")
        //SwiftSpinner.show("Patient created", animated: true)
        self.searchForDevice()
    }
    
    func deviceNotFound() {
        print("deviceNotFound")
        //SwiftSpinner.show("Device not found", animated: true)
        self.createDevice()
    }
    
    func deviceFound(deviceID:String) {
        print("device found, ID: \(deviceID)")
        //SwiftSpinner.show("Device found", animated: true)
        if(glucoseMeasurements.count == 1) {
            self.searchForObservation(measurement: glucoseMeasurements[0])
        } else {
            self.uploadMeasurements()
        }
    }
    
    func deviceCreated(deviceID:String) {
        print("device created, ID: \(deviceID)")
        //SwiftSpinner.show("Device created", animated: true)
        if(glucoseMeasurements.count == 1) {
            self.searchForObservation(measurement: glucoseMeasurements[0])
        } else {
            self.uploadMeasurements()
        }
    }
    
    public func observationNotFound() {
        print("observationNotFound")
        self.uploadMeasurements()
    }
    
    public func observationFound(observationID: String) {
        print("observation found, ID: \(observationID)")
    }
    
    func observationCreated(observationID:String) {
        print("observation uploaded, ID: \(observationID)")
        SwiftSpinner.show("Observation uploaded").addTapHandler({
            SwiftSpinner.hide()
        })
    }
    
    func bundleCreated(bundleID:String) {
        print("bundle uploaded, ID: \(bundleID)")
        SwiftSpinner.show(duration: 1.5, title: "Bundle uploaded", animated: false)
    }
}
