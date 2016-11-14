//
//  FHIR.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 9/30/16.
//  Copyright © 2016 eHealth Innovation. All rights reserved.
//

import Foundation
import SMART

public protocol FHIRProtocol {
    func error(error:Error)
    func patientNotFound()
    func patientFound(patientID:String)
    func patientCreated(patientID:String)
    func deviceNotFound()
    func deviceFound(deviceID:String)
    func deviceCreated(deviceID:String)
    func observationCreated(observationID:String)
    func observationFound(observationID:String)
    func observationNotFound()
    func bundleCreated(bundleID:String)
}

class FHIR: NSObject {
    public var FHIRDelegate: FHIRProtocol?
    
    public var patient: Patient?
    public var device: Device?
    public var observation: Observation?
    
    var smart: Client?
    var server: FHIRServer?
    
    public override init() {
        super.init()
        let url = URL(string: "https://fhirtest.uhn.ca/baseDstu2")
        server = Server(baseURL: url!)
        
        smart = Client(
            baseURL: "https://fhirtest.uhn.ca/baseDstu2",
            settings: [
                "client_id": "glucoseOnFhirApp",
                "client_name": "Glucose on FHIR iOS",
                "redirect": "smartapp://callback",
                "verbose": true,
                ]
        )
    }
    
    public func createPatient(patient: Patient) {
        patient.createAndReturn(server!) { error in
            guard error == nil else {
                print(error!)
                self.FHIRDelegate?.error(error: error!)
                return
            }
            
            print(patient.id!)
            
            self.patient = patient
            self.FHIRDelegate?.patientCreated(patientID: patient.id!)
        }
    }
    
    public func searchForPatient(searchParameters:Dictionary<String, Any>) {
        let searchPatient = Patient.search(searchParameters)
        
        searchPatient.perform((smart?.server)!) { bundle, error in
            if nil != error {
                print(error!)
                self.FHIRDelegate?.error(error: error!)
            }
            else {
                if(bundle?.entry != nil) {
                    let patients = bundle?.entry?
                        .filter() { return $0.resource is Patient }
                        .map() { return $0.resource as! Patient }
                
                    print(patients!)
                    self.patient = patients?[0]
                    self.FHIRDelegate?.patientFound(patientID: (self.patient?.id)!)
                } else {
                    self.FHIRDelegate?.patientNotFound()
                }
            }
        }
    }
    
    public func searchForPatientByID(idString:String) {
        let searchPatient = Patient.search(["_id": idString])
        
        searchPatient.perform((smart?.server)!) { bundle, error in
            if nil != error {
                print(error!)
                self.FHIRDelegate?.error(error: error!)
            }
            else {
                if(bundle?.entry != nil) {
                    let patients = bundle?.entry?
                        .filter() { return $0.resource is Patient }
                        .map() { return $0.resource as! Patient }
                    
                    print(patients!)
                    self.patient = patients?[0]
                    self.FHIRDelegate?.patientFound(patientID: (self.patient?.id)!)
                } else {
                    self.FHIRDelegate?.patientNotFound()
                }
            }
        }
    }
    
    public func createDevice(device: Device) {
        device.createAndReturn(server!) { error in
            guard error == nil else {
                print(error!)
                self.FHIRDelegate?.error(error: error!)
                return
            }
            
            print(device.id!)
            
            self.device = device
            self.FHIRDelegate?.deviceCreated(deviceID: device.id!)
        }
    }
    
    public func searchForDevice(searchParameters:Dictionary<String, Any>) {
        let searchDevice = Device.search(searchParameters)
        
        searchDevice.perform((smart?.server)!) { bundle, error in
            if nil != error {
                print(error!)
                self.FHIRDelegate?.error(error: error!)
            }
            else {
                if(bundle?.entry != nil) {
                    let devices = bundle?.entry?
                        .filter() { return $0.resource is Device }
                        .map() { return $0.resource as! Device }
                
                    print(devices!)
                    self.device = devices?[0]
                    self.FHIRDelegate?.deviceFound(deviceID: (self.device?.id)!)
                } else {
                    self.FHIRDelegate?.deviceNotFound()
                }
            }
        }
    }
    
    public func searchForObservationByID(idString:String) {
        let searchObservation = Observation.search(["_id": idString])
        
        searchObservation.perform((smart?.server)!) { bundle, error in
            if nil != error {
                print(error!)
                self.FHIRDelegate?.error(error: error!)
            }
            else {
                if(bundle?.entry != nil) {
                    let observations = bundle?.entry?
                        .filter() { return $0.resource is Observation }
                        .map() { return $0.resource as! Observation }
                    
                    print(observations!)
                    self.observation = observations?[0]
                    self.FHIRDelegate?.observationFound(observationID: (self.observation?.id)!)
                } else {
                    self.FHIRDelegate?.observationNotFound()
                }
            }
        }
    }
    
    public func searchForObservation(searchParameters:Dictionary<String, Any>) {
        let searchObservation = Observation.search(searchParameters)
        
        searchObservation.perform((smart?.server)!) { bundle, error in
            if nil != error {
                print(error!)
                self.FHIRDelegate?.error(error: error!)
            }
            else {
                if(bundle?.entry != nil) {
                    let observations = bundle?.entry?
                        .filter() { return $0.resource is Observation }
                        .map() { return $0.resource as! Observation }
                    
                    print(observations!)
                    self.observation = observations?[0]
                    self.FHIRDelegate?.observationFound(observationID: (self.observation?.id)!)
                } else {
                    self.FHIRDelegate?.observationNotFound()
                }
            }
        }
    }

    public func createObservation(observation:Observation) {
        observation.createAndReturn(server!) { error in
            guard error == nil else {
                print(error!)
                self    .FHIRDelegate?.error(error: error!)
                return
            }
            
            print(observation.id!)
            self.FHIRDelegate?.observationCreated(observationID: observation.id!)
        }
    }
    
    public func createObservationBundle(observations: [Observation]) {
        let bundle = Bundle(json: nil)
        bundle.type = "transaction"
    
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
                self.FHIRDelegate?.error(error: error)
            }
            else {
                print("Bundle created, has id \(bundle.id)")
                self.FHIRDelegate?.bundleCreated(bundleID: bundle.id!)
            }
        }
    }
}
