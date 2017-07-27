//
//  BGMFhir.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 7/11/17.
//  Copyright © 2017 eHealth Innovation. All rights reserved.
//

// swiftlint:disable function_body_length
// swiftlint:disable line_length
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length

import Foundation
import CCGlucose
import SMART

public class BGMFhir: NSObject {
    static let BGMFhirInstance: BGMFhir = BGMFhir()
    var patient: Patient?
    var device: Device?
    var deviceComponent: DeviceComponent?
    var specimen: Specimen?
    
    var givenName: FHIRString = "Lisa"
    var familyName: FHIRString = "Simpson"
    
    public func createPatient(callback: @escaping (_ patient: Patient, _ error: Error?) -> Void) {
        let patientName = HumanName()
        patientName.family = self.familyName
        patientName.given = [self.givenName]
        patientName.use = NameUse(rawValue: "official")
        
        let patientTelecom = ContactPoint()
        patientTelecom.use = ContactPointUse(rawValue: "work")
        patientTelecom.value = "4163404800"
        patientTelecom.system = ContactPointSystem(rawValue: "phone")
        
        let patientAddress = Address()
        patientAddress.city = "Toronto"
        patientAddress.country = "Canada"
        patientAddress.postalCode = "M5G2C4"
        patientAddress.line = ["585 University Ave"]
        
        let patientBirthDate = FHIRDate(string: DateTime.now.date.description)
        
        let patient = Patient()
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
    
    public func searchForPatient(given: String, family: String, callback: @escaping FHIRSearchBundleErrorCallback) {
        print("GlucoseMeterViewController: searchForPatient")
        let searchDict: [String:Any] = [
            "given": given,
            "family": family
        ]
        
        FHIR.fhirInstance.searchForPatient(searchParameters: searchDict) { (bundle, error) -> Void in
            if let error = error {
                print("error searching for patient: \(error)")
            }
            
            if bundle?.entry == nil {
                
            } else {
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
    
    func searchForDevice(callback: @escaping FHIRSearchBundleErrorCallback) {
        let modelNumber = Glucose.sharedInstance().modelNumber!.replacingOccurrences(of: "\0", with: "")
        let manufacturer = Glucose.sharedInstance().manufacturerName!.replacingOccurrences(of: "\0", with: "")
        
        let encodedModelNumber: String = modelNumber.replacingOccurrences(of: " ", with: "+")
        let encodedMmanufacturer: String = manufacturer.replacingOccurrences(of: " ", with: "+")
        
        let searchDict: [String:Any] = [
            "model": encodedModelNumber,
            "manufacturer": encodedMmanufacturer,
            "identifier": Glucose.sharedInstance().serialNumber!
        ]
        
        FHIR.fhirInstance.searchForDevice(searchParameters: searchDict) { (bundle, error) -> Void in
            if let error = error {
                print("error searching for device: \(error)")
            }
            
            if bundle?.entry == nil {
                print("device not found")
            } else {
                print("device found")
                
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
    
    func createDevice(callback: @escaping (_ device: Device, _ error: Error?) -> Void) {
        let modelNumber = Glucose.sharedInstance().modelNumber!.replacingOccurrences(of: "\0", with: "")
        let manufacturer = Glucose.sharedInstance().manufacturerName!.replacingOccurrences(of: "\0", with: "")
        let serialNumber = Glucose.sharedInstance().serialNumber!.replacingOccurrences(of: "\0", with: "")
        
        let deviceCoding = Coding()
        deviceCoding.code = "337414009"
        deviceCoding.system = FHIRURL.init("http://snomed.info/sct")
        deviceCoding.display = "Blood glucose meters (physical object)"
        
        let deviceType = CodeableConcept()
        deviceType.coding = [deviceCoding]
        deviceType.text = "Glucose Meter"
        
        let deviceIdentifierTypeCoding = Coding()
        deviceIdentifierTypeCoding.system = FHIRURL.init("http://hl7.org/fhir/identifier-type")
        deviceIdentifierTypeCoding.code = "SNO"
        
        let deviceIdentifierType = CodeableConcept()
        deviceIdentifierType.coding = [deviceIdentifierTypeCoding]
        
        let deviceIdentifier = Identifier()
        deviceIdentifier.value = FHIRString.init(serialNumber)
        deviceIdentifier.type = deviceIdentifierType
        deviceIdentifier.system = FHIRURL.init("http://www.company.com/products/product/serial")
        
        let device = Device()
        device.status = FHIRDeviceStatus(rawValue: "available")
        device.manufacturer = FHIRString.init(manufacturer)
        device.model = FHIRString.init(modelNumber)
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
    
    public func createDeviceComponent(callback: @escaping (_ error: Error?) -> Void) {
        let deviceComponent = DeviceComponent()
        
        var productSpec = [DeviceComponentProductionSpecification]()
        var codingArray = [Coding]()
        
        //hardware revision
        if Glucose.sharedInstance().hardwareVersion != nil {
            let hardwareRevision = DeviceComponentProductionSpecification()
            hardwareRevision.productionSpec = FHIRString.init(Glucose.sharedInstance().hardwareVersion!)
        
            let hardwareRevisionCoding = Coding()
            hardwareRevisionCoding.code = "hardware-revision"
            hardwareRevisionCoding.display = "Hardware Revision"
            codingArray.append(hardwareRevisionCoding)
        
            let hardwareRevisionCodableConcept = CodeableConcept()
            hardwareRevisionCodableConcept.coding = codingArray
        
            hardwareRevision.specType = hardwareRevisionCodableConcept
            productSpec.append(hardwareRevision)
        }
        
        //software revision
        if Glucose.sharedInstance().softwareVersion != nil {
            let softwareRevision = DeviceComponentProductionSpecification()
            softwareRevision.productionSpec = FHIRString.init(Glucose.sharedInstance().softwareVersion!)
        
            let softwareRevisionCoding = Coding()
            softwareRevisionCoding.code = "software-revision"
            softwareRevisionCoding.display = "Software Revision"
            codingArray.removeAll()
            codingArray.append(softwareRevisionCoding)
        
            let softwareRevisionCodableConcept = CodeableConcept()
            softwareRevisionCodableConcept.coding = codingArray
        
            softwareRevision.specType = softwareRevisionCodableConcept
            productSpec.append(softwareRevision)
        }
        
        //firmware revision
        if Glucose.sharedInstance().firmwareVersion != nil {
            let firmwareRevision = DeviceComponentProductionSpecification()
            firmwareRevision.productionSpec = FHIRString.init(Glucose.sharedInstance().firmwareVersion!)
        
            let firmwareRevisionCoding = Coding()
            firmwareRevisionCoding.code = "firmware-revision"
            firmwareRevisionCoding.display = "Firmware Revision"
            codingArray.removeAll()
            codingArray.append(firmwareRevisionCoding)
        
            let firmwareRevisionCodableConcept = CodeableConcept()
            firmwareRevisionCodableConcept.coding = codingArray
        
            firmwareRevision.specType = firmwareRevisionCodableConcept
            productSpec.append(firmwareRevision)
        }
        
        deviceComponent.productionSpecification = productSpec
        
        let deviceReference = Reference()
        deviceReference.reference = FHIRString.init("Device/\(String(describing: self.device!.id!))")
        deviceComponent.source = deviceReference
        
        let deviceIdentifier = Identifier()
        deviceIdentifier.value = FHIRString.init(Glucose.sharedInstance().serialNumber!)
        deviceComponent.identifier = deviceIdentifier
        
        var deviceCodingArray = [Coding]()
        let deviceCoding = Coding()
        deviceCoding.code = FHIRString.init("160368")
        deviceCoding.display = FHIRString.init("MDC_CONC_GLU_UNDETERMINED_PLASMA")
        deviceCoding.system = FHIRURL.init("urn.iso.std.iso:11073:10101")!
        deviceCodingArray.append(deviceCoding)
        
        let deviceType = CodeableConcept()
        deviceType.coding = deviceCodingArray
        deviceComponent.type = deviceType
        
        FHIR.fhirInstance.createDeviceComponent(deviceComponent: deviceComponent) { deviceComponent, error in
            if let error = error {
                print("error creating device: \(error)")
            } else {
                self.deviceComponent = deviceComponent
            }
            callback(error)
        }
    }
    
    func searchForObservations(measurements: [GlucoseMeasurement]) {
        for measurement in measurements {
            self.searchForObservation(measurement: measurement) { (bundle, error) -> Void in
                if let error = error {
                    print("error searching for observation: \(error)")
                }
                
                if bundle?.entry == nil {
                    print("measurement \(measurement.sequenceNumber) not found")
                    measurement.existsOnFHIR = false
                } else {
                    print("measurement \(measurement.sequenceNumber) found")
                    measurement.existsOnFHIR = true
                    measurement.fhirID = String(describing: bundle?.entry?.first?.resource?.id)
                }
            }
        }
    }
    
    func searchForObservation(measurement: GlucoseMeasurement, callback: @escaping FHIRSearchBundleErrorCallback) {
        let truncatedMeasurement = String(describing: measurement.toMMOL()!.truncateMeasurement())
        
        let searchDict: [String: Any] = [
            "subject": String(describing: BGMFhir.BGMFhirInstance.patient!.id!),
            "date": measurement.dateTime?.iso8601 as Any,
            "code": "http://loinc.org|15074-8",
            "value-quantity": (truncatedMeasurement as String) + "|http://unitsofmeasure.org|mmol/L"
        ]
        
        FHIR.fhirInstance.searchForObservation(searchParameters: searchDict) { bundle, error in
            if let error = error {
                print("error searching for observation: \(error)")
            }
            
            if bundle?.entry != nil {
                print("measurement \(measurement.sequenceNumber) found")
                measurement.existsOnFHIR = true
                measurement.fhirID = String(describing: bundle!.entry!.first!.resource!.id!)
            }
            
            callback(bundle, error)
        }
    }

    func uploadSingleMeasurement(measurement: GlucoseMeasurement, callback: @escaping (_ observation: Observation, _ error: Error?) -> Void) {
        if measurement.existsOnFHIR == false {
            FHIR.fhirInstance.createObservation(observation: self.measurementToObservation(measurement: measurement)) { (observation, error) -> Void in
                guard error == nil else {
                    print("error creating observation: \(String(describing: error))")
                    return
                }
                
                print("observation uploaded with id: \(observation.id!)")
                measurement.existsOnFHIR = true
                measurement.fhirID = String(describing: observation.id!)
        
                callback(observation, error)
            }
        }
    }

    func uploadObservationBundle(measurements: [GlucoseMeasurement], callback: @escaping FHIRSearchBundleErrorCallback) {
        var pendingObservations: [Observation] = []
        var measurementArrayLocation: [Int] = []
        
        for i in 0...measurements.count - 1 {
            if measurements[i].existsOnFHIR == false {
                print("measurement pending: \(i)")
                pendingObservations.append(self.measurementToObservation(measurement: measurements[i]))
                measurementArrayLocation.append(i)
            }
        }
        
        if pendingObservations.count == 0 {
            return
        }
        
        FHIR.fhirInstance.createObservationBundle(observations: pendingObservations) { (bundle, error) -> Void in
            guard error == nil else {
                print("error creating observations: \(String(describing: error))")
                return
            }
            
            if let count = bundle?.entry?.count {
                //iterate through the batch response entries, start from 1 (zero is not a observation response)
                for i in 1...count-1 {
                    if bundle?.entry?[i].response?.status == "201 Created" {
                        let components = bundle?.entry?[i].response?.location?.absoluteString.components(separatedBy: "/")
                        measurements[measurementArrayLocation[i-1]].existsOnFHIR = true
                        measurements[measurementArrayLocation[i-1]].fhirID = components![1]
                        
                        print("observation uploaded with ID \(components![1])")
                    }
                }
            } else {
                print("problem uploading bundle, count is zero")
            }
            
            callback(bundle, error)
        }
    }
    
    func measurementToObservation(measurement: GlucoseMeasurement) -> Observation {
        var codingArray = [Coding]()
        let coding = Coding()
        coding.system = FHIRURL.init("http://loinc.org")
        coding.code = "15074-8"
        coding.display = "Glucose [Moles/volume] in Blood"
        codingArray.append(coding)
        
        let codableConcept = CodeableConcept()
        codableConcept.coding = codingArray as [Coding]
        
        let deviceReference = Reference()
        deviceReference.reference = FHIRString.init("Device/\(String(describing: BGMFhir.BGMFhirInstance.device!.id!))")
        
        let subjectReference = Reference()
        subjectReference.reference = FHIRString.init("Patient/\(String(describing: BGMFhir.BGMFhirInstance.patient!.id!))")
        
        var performerArray = [Reference]()
        let performerReference = Reference()
        performerReference.reference = FHIRString.init("Patient/\(String(describing: BGMFhir.BGMFhirInstance.patient!.id!))")
        performerArray.append(performerReference)
        
        let measurementNumber = NSDecimalNumber(value: (measurement.toMMOL()?.truncateMeasurement())!)
        let decimalRoundingBehaviour = NSDecimalNumberHandler(roundingMode:.plain,
                                                              scale: 2, raiseOnExactness: false,
                                                              raiseOnOverflow: false, raiseOnUnderflow:
            false, raiseOnDivideByZero: false)
        
        let quantity = Quantity.init()
        quantity.value = FHIRDecimal.init(String(describing: measurementNumber.rounding(accordingToBehavior: decimalRoundingBehaviour)))
        quantity.code = "mmol/L"
        quantity.system = FHIRURL.init("http://unitsofmeasure.org")
        quantity.unit = "mmol/L"
        
        let effectivePeriod = Period()
        effectivePeriod.start = DateTime(string: (measurement.dateTime?.iso8601)!)
        effectivePeriod.end = DateTime(string: (measurement.dateTime?.iso8601)!)
        
        let observation = Observation.init()
        observation.status = ObservationStatus(rawValue: "final")
        observation.code = codableConcept
        observation.valueQuantity = quantity
        observation.effectivePeriod = effectivePeriod
        observation.device = deviceReference
        observation.subject = subjectReference
        observation.performer = performerArray
        
        if measurement.contextInformationFollows {
            var observationExtensionArray = [Extension]()
            let bluetoothGlucoseMeasurementContextURL: String = "https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.glucose_measurement_context.xml"
            
            if measurement.context != nil {
                // Carbohydrate ID
                if measurement.context?.carbohydrateID?.description != nil {
                    let extensionElementCoding = Coding()
                    extensionElementCoding.system = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = FHIRString.init((String(describing:measurement.context?.carbohydrateID?.rawValue.description)))
                    extensionElementCoding.display = FHIRString.init((String(describing:measurement.context?.carbohydrateID?.description)))
                    
                    let extensionElement = Extension()
                    extensionElement.url = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Carbohydrate Weight
                if measurement.context?.carbohydrateWeight?.description != nil {
                    let extensionElementCoding = Coding()
                    extensionElementCoding.system = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = FHIRString.init((String(describing:measurement.context?.carbohydrateWeight!.description)))
                    extensionElementCoding.display = FHIRString.init((String(describing:measurement.context?.carbohydrateWeight!.description)))
                    
                    let extensionElement = Extension()
                    extensionElement.url = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Meal
                if measurement.context?.meal?.description != nil {
                    let extensionElementCoding = Coding()
                    extensionElementCoding.system = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = FHIRString.init((String(describing:measurement.context?.meal?.rawValue.description)))
                    extensionElementCoding.display = FHIRString.init((String(describing:measurement.context?.meal?.description)))
                    
                    let extensionElement = Extension()
                    extensionElement.url = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Tester
                if measurement.context?.tester?.description != nil {
                    let extensionElementCoding = Coding()
                    extensionElementCoding.system = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = FHIRString.init((String(describing:measurement.context?.tester)))
                    extensionElementCoding.display = FHIRString.init((String(describing:measurement.context?.tester?.description)))
                    
                    let extensionElement = Extension()
                    extensionElement.url = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Health
                if measurement.context?.health?.description != nil {
                    let extensionElementCoding = Coding()
                    extensionElementCoding.system = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = FHIRString.init((String(describing:measurement.context?.health)))
                    extensionElementCoding.display = FHIRString.init((String(describing:measurement.context?.health?.description)))
                    
                    let extensionElement = Extension()
                    extensionElement.url = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Exercise Duration
                if measurement.context?.exerciseDuration?.description != nil {
                    let extensionElementCoding = Coding()
                    extensionElementCoding.system = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = FHIRString.init((String(describing:measurement.context?.exerciseDuration?.description)))
                    extensionElementCoding.display = FHIRString.init((String(describing:measurement.context?.exerciseDuration?.description)))
                    
                    let extensionElement = Extension()
                    extensionElement.url = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Exercise Intensity
                if measurement.context?.exerciseIntensity?.description != nil {
                    let extensionElementCoding = Coding()
                    extensionElementCoding.system = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = FHIRString.init((String(describing:measurement.context?.exerciseIntensity?.description)))
                    extensionElementCoding.display = FHIRString.init((String(describing:measurement.context?.exerciseIntensity?.description)))
                    
                    let extensionElement = Extension()
                    extensionElement.url = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Medication ID
                if measurement.context?.medicationID?.description != nil {
                    let extensionElementCoding = Coding()
                    extensionElementCoding.system = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = FHIRString.init((String(describing:measurement.context?.medicationID?.description)))
                    extensionElementCoding.display = FHIRString.init((String(describing:measurement.context?.medicationID?.description)))
                    
                    let extensionElement = Extension()
                    extensionElement.url = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // Medication
                if measurement.context?.medication?.description != nil {
                    let extensionElementCoding = Coding()
                    extensionElementCoding.system = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = FHIRString.init((String(describing:measurement.context?.medication!.description)))
                    extensionElementCoding.display = FHIRString.init((String(describing:measurement.context?.medication!.description)))
                    
                    let extensionElement = Extension()
                    extensionElement.url = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
                
                // hbA1c
                if measurement.context?.hbA1c?.description != nil {
                    let extensionElementCoding = Coding()
                    extensionElementCoding.system = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElementCoding.code = FHIRString.init((String(describing:measurement.context?.hbA1c?.description)))
                    extensionElementCoding.display = FHIRString.init((String(describing:measurement.context?.hbA1c?.description)))
                    
                    let extensionElement = Extension()
                    extensionElement.url = FHIRURL.init(bluetoothGlucoseMeasurementContextURL)
                    extensionElement.valueCoding = extensionElementCoding
                    
                    observationExtensionArray.append(extensionElement)
                }
            }
            observation.extension_fhir = observationExtensionArray
        }
        return observation
    }
    
    public func createSpecimen() {
        let specimen = Specimen()
        let specimenCollection = SpecimenCollection()
        
        let bodySiteCoding = Coding()
        bodySiteCoding.system = FHIRURL.init("https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.glucose_measurement.xml")
        bodySiteCoding.code = FHIRString.init(String(describing:"1"))
        bodySiteCoding.display = FHIRString.init(String(describing:"Finger"))
        
        let bodySite = CodeableConcept()
        bodySite.coding = [bodySiteCoding]
        specimenCollection.bodySite = bodySite
        specimen.collection = specimenCollection
        
        let deviceReference = Reference()
        deviceReference.reference = FHIRString.init("Device/\(String(describing: self.device!.id!))")
        specimen.subject = deviceReference
        
        let typeCoding = Coding()
        typeCoding.system = FHIRURL.init("https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.glucose_measurement.xml")
        typeCoding.code = FHIRString.init(String(describing:"1"))
        typeCoding.display = FHIRString.init(String(describing:"Capillary Whole blood"))
        
        let type = CodeableConcept()
        type.coding = [typeCoding]
        
        specimen.type = type
        
        FHIR.fhirInstance.createSpecimen(specimen: specimen) { (specimen, error) -> Void in
            guard error == nil else {
                print("error creating specimen: \(String(describing: error))")
                return
            }
            
            print("specimen uploaded with id: \(specimen.id!)")
            self.specimen = specimen
        }
    }
    
    public func searchForSpecimen(callback: @escaping FHIRSearchBundleErrorCallback) {
        print("GlucoseMeterViewController: searchForSpecimen")
        let bodySite: String = String(describing: "1")
        let type = String(describing: "1")
        
        let searchDict: [String:Any] = [
            "bodysite": bodySite,
            "type": type,
            "subject": String(describing: "Device/\(self.device!.id!)")
        ]
        
        FHIR.fhirInstance.searchForSpecimen(searchParameters: searchDict) { (bundle, error) -> Void in
            if let error = error {
                print("error searching for specimen: \(error)")
            }
            
            if bundle?.entry == nil {
                
            } else {
                if bundle?.entry != nil {
                    let specimens = bundle?.entry?
                        .filter { return $0.resource is Specimen }
                        .map { return $0.resource as! Specimen }
                    
                    self.specimen = specimens?[0]
                }
            }
            callback(bundle, error)
        }
    }
}
