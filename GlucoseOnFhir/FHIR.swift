//
//  FHIR.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 9/30/16.
//  Copyright © 2016 eHealth Innovation. All rights reserved.
//

// Swift rules
// swiftlint:disable colon
// swiftlint:disable syntactic_sugar

import Foundation
import SMART

class FHIR: NSObject {
    var smart: Client?
    public var server: FHIRServer?
    public var fhirServerAddress: String = "fhirtest.uhn.ca"
    static let fhirInstance: FHIR = FHIR()
    
    public override init() {
        super.init()
        print("fhir: init - \(fhirServerAddress)")
        
        setFHIRServerAddress(address:self.fhirServerAddress)
    }
    
    public func setFHIRServerAddress(address:String) {
        print("setFHIRServerAddress: \(address)")
        
        self.fhirServerAddress = address
        
        let url = URL(string: "http://" + fhirServerAddress + "/baseDstu3")
        server = Server(baseURL: url!)
        
        smart = Client(
            baseURL: url!,
            settings: [
                "client_id": "glucoseOnFhirApp",
                "client_name": "Glucose on FHIR iOS",
                "redirect": "smartapp://callback",
                "verbose": true
            ]
        )
    }
    
    public func createPatient(patient: Patient, callback: @escaping (_ patient: Patient, _ error: Error?) -> Void) {
        patient.createAndReturn(server!) { error in
            if let error = error {
                print("createPatient error: \(error)")
            }
            
            callback(patient, error)
        }
    }
    
    public func searchForPatient(searchParameters: Dictionary<String, Any>, callback: @escaping FHIRSearchBundleErrorCallback) {
        print("fhir: searchForPatient")
        let searchPatient = Patient.search(searchParameters)
        
        searchPatient.perform((smart?.server)!) { bundle, error in
            if let error = error {
                print(error)
            }
            
            callback(bundle, error)
        }
    }
    
    public func createDeviceComponent(deviceComponent: DeviceComponent, callback: @escaping (_ device: DeviceComponent, _ error: Error?) -> Void) {
        deviceComponent.createAndReturn(server!) { error in
            if let error = error {
                print(error)
            }
            
            callback(deviceComponent, error)
        }
    }
    
    public func searchForDeviceComponent(searchParameters: Dictionary<String, Any>, callback: @escaping FHIRSearchBundleErrorCallback) {
        let searchDeviceComponent = DeviceComponent.search(searchParameters)
        print("fhir: searchForDeviceComponent")
        
        searchDeviceComponent.perform((smart?.server)!) { bundle, error in
            if let error = error {
                print(error)
            }
            
            callback(bundle, error)
        }
    }
    
    public func createDevice(device: Device, callback: @escaping (_ device: Device, _ error: Error?) -> Void) {
        device.createAndReturn(server!) { error in
            if let error = error {
                print(error)
            }
            
            callback(device, error)
        }
    }
    
    public func searchForDevice(searchParameters: Dictionary<String, Any>, callback: @escaping FHIRSearchBundleErrorCallback) {
        let searchDevice = Device.search(searchParameters)
        print("fhir: searchForDevice")
        
        searchDevice.perform((smart?.server)!) { bundle, error in
            if let error = error {
                print(error)
            }
            
            callback(bundle, error)
        }
    }
    
    public func searchForObservationByID(idString:String, callback: @escaping FHIRSearchBundleErrorCallback) {
        let searchObservation = Observation.search(["_id": idString])
        
        searchObservation.perform((smart?.server)!) { bundle, error in
            if let error = error {
                print(error)
            }
            
            callback(bundle, error)
        }
    }
    
    public func searchForObservation(searchParameters: Dictionary<String, Any>, callback: @escaping FHIRSearchBundleErrorCallback) {
        let searchObservation = Observation.search(searchParameters)
        
        searchObservation.perform((smart?.server)!) { bundle, error in
            if let error = error {
                print(error)
            }
            
            callback(bundle, error)
        }
    }
    
    public func createObservation(observation:Observation, callback: @escaping (_ observation: Observation, _ error: Error?) -> Void) {
        observation.createAndReturn(server!) { error in
            if let error = error {
                print(error)
            }
            
            callback(observation, error)
        }
    }
    
    public func createSpecimen(specimen: Specimen, callback: @escaping (_ specimen: Specimen, _ error: Error?) -> Void) {
        specimen.createAndReturn(server!) { error in
            if let error = error {
                print(error)
            }
            
            callback(specimen, error)
        }
    }
    
    public func searchForSpecimen(searchParameters: Dictionary<String, Any>, callback: @escaping FHIRSearchBundleErrorCallback) {
        print("fhir: searchForSpecimen")
        let searchSpecimen = Specimen.search(searchParameters)
        
        searchSpecimen.perform((smart?.server)!) { bundle, error in
            if let error = error {
                print(error)
            }
            
            callback(bundle, error)
        }
    }
    
    public func createObservationBundle(observations:[Observation], callback: @escaping FHIRSearchBundleErrorCallback) {
        let bundle = SMART.Bundle()
        bundle.type = BundleType.batch
        
        bundle.entry = observations.map {
            let entry = BundleEntry()
            entry.resource = $0
            
            let httpVerb = HTTPVerb(rawValue: "POST")
            let entryRequest = BundleEntryRequest(method: httpVerb!, url: FHIRURL.init((self.server?.baseURL)!))
            entry.request = entryRequest
            
            return entry
        }
        
        bundle.createAndReturn(self.server!) { error in
            if let error = error {
                print(error)
            }
            
            callback(bundle, error)
        }
    }
}
