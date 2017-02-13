//
//  FHIR.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 9/30/16.
//  Copyright © 2016 eHealth Innovation. All rights reserved.
//

import Foundation
import SMART

class FHIR: NSObject {
    var smart: Client?
    var server: FHIRServer?
    public var fhirServerAddress: String = "fhirtest.uhn.ca"
    static let sharedInstance: FHIR = FHIR()
    
    public override init() {
        super.init()
        print("fhir: init - \(fhirServerAddress)")
        
        setFHIRServerAddress(address:self.fhirServerAddress)
    }
    
    public func setFHIRServerAddress(address:String) {
        print("setFHIRServerAddress: \(address)")
        
        self.fhirServerAddress = address
        
        let url = URL(string: "http://" + fhirServerAddress + "/baseDstu2")
        server = Server(baseURL: url!)
        
        smart = Client(
            baseURL: "http://" + fhirServerAddress + "/baseDstu2",
            settings: [
                "client_id": "glucoseOnFhirApp",
                "client_name": "Glucose on FHIR iOS",
                "redirect": "smartapp://callback",
                "verbose": true,
                ]
        )
    }
    
    public func createPatient(patient: Patient, callback: @escaping (_ patient: Patient, _ error: Error?) -> Void) {
        patient.createAndReturn(server!) { error in
            guard error == nil else {
                print(error!)
                callback(patient, error)
                return
            }
            
            callback(patient, error)
        }
    }
    
    public func searchForPatient(searchParameters:Dictionary<String, Any>, callback: @escaping FHIRSearchBundleErrorCallback) {
        print("fhir: searchForPatient")
        let searchPatient = Patient.search(searchParameters)
        
        searchPatient.perform((smart?.server)!) { bundle, error in
            if nil != error {
                print(error!)
                callback(bundle, error)
            }
            else {
                callback(bundle, error)
            }
        }
    }
    
    public func createDevice(device: Device, callback: @escaping (_ device: Device, _ error: Error?) -> Void) {
        device.createAndReturn(server!) { error in
            guard error == nil else {
                print(error!)
                callback(device, error)
                return
            }
            
            callback(device, error)
        }
    }
    
    public func searchForDevice(searchParameters:Dictionary<String, Any>, callback: @escaping FHIRSearchBundleErrorCallback) {
        let searchDevice = Device.search(searchParameters)
        
        searchDevice.perform((smart?.server)!) { bundle, error in
            if nil != error {
                print(error!)
                callback(bundle, error)
            }
            else {
                callback(bundle, error)
            }
        }
    }
    
    public func searchForObservationByID(idString:String, callback: @escaping FHIRSearchBundleErrorCallback) {
        let searchObservation = Observation.search(["_id": idString])
        
        searchObservation.perform((smart?.server)!) { bundle, error in
            if nil != error {
                print(error!)
                callback(bundle,error)
            }
            else {
                callback(bundle,error)
            }
        }
    }
    
    public func searchForObservation(searchParameters:Dictionary<String, Any>, callback: @escaping FHIRSearchBundleErrorCallback) {
        let searchObservation = Observation.search(searchParameters)
        
        searchObservation.perform((smart?.server)!) { bundle, error in
            if nil != error {
                print(error!)
                callback(bundle,error)
            }
            else {
                if(bundle?.entry != nil) {
                    let observations = bundle?.entry?
                        .filter() { return $0.resource is Observation }
                        .map() { return $0.resource as! Observation }
                    
                    print(observations!)
                    callback(bundle,error)
                } else {
                    callback(bundle,error)
                }
            }
        }
    }

    public func createObservation(observation:Observation, callback: @escaping (_ observation: Observation, _ error: Error?) -> Void) {
        observation.createAndReturn(server!) { error in
            guard error == nil else {
                print(error!)
                callback(observation, error)
                return
            }
            
            callback(observation, error)
        }
    }
    
    public func createObservationBundle(type: String, observations:[Observation], callback: @escaping FHIRSearchBundleErrorCallback) {
        let bundle = Bundle(json: nil)
        bundle.type = type
        
        bundle.entry = observations.map() {
            let entry = BundleEntry(json: nil)
            entry.resource = $0

            let entryRequest = BundleEntryRequest(method: "POST", url: (self.server?.baseURL)!)
            entry.request = entryRequest
    
            return entry
        }
    
        bundle.createAndReturn(self.server!) { error in
            if let error = error {
                print("FAILED: \(error)")
                callback(bundle, error)
            }
            else {
                print("bundle: \(bundle.asJSON())")
                callback(bundle, error)
            }
        }
    }
}
