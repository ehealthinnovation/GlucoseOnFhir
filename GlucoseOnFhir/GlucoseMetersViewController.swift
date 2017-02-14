//
//  ViewController.swift
//  GlucoseOnFhir
//
//  Created by Kevin Tallevi on 9/29/16.
//  Copyright © 2016 eHealth Innovation. All rights reserved.
//

import Foundation
import UIKit
import CCBluetooth
import CCGlucose
import CoreBluetooth

class GlucoseMetersViewController: UITableViewController, GlucoseMeterDiscoveryProtocol, Refreshable {
    private var glucose: Glucose?
    let cellIdentifier = "GlucoseMetersCellIdentifier"
    var discoveredGlucoseMeters: Array<CBPeripheral> = Array<CBPeripheral>()
    var previouslySelectedGlucoseMeters: Array<CBPeripheral> = Array<CBPeripheral>()
    var peripheral: CBPeripheral!
    let rc = UIRefreshControl()
    let browser = NetServiceBrowser()
    var fhirService = NetService()
    var fhirServiceIP: String?
    @IBOutlet weak var discoverFHIRServersButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("GlucoseMetersViewController#viewDidLoad")
        
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl?.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        
        glucose = Glucose()
        glucose?.glucoseMeterDiscoveryDelegate = self
    }
    
    func onRefresh() {
        refreshControl?.endRefreshing()
        discoveredGlucoseMeters.removeAll()
        
        self.refresh()
        
        glucose = Glucose()
        glucose?.glucoseMeterDiscoveryDelegate = self
        glucose?.scanForGlucoseMeters()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.refresh()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let GlucoseMeterVC = segue.destination as! GlucoseMeterViewController
        GlucoseMeterVC.glucoseMeter = self.peripheral
    }
    
    func glucoseMeterDiscovered(glucoseMeter:CBPeripheral) {
        print("GlucoseMeterViewControllers#glucoseMeterDiscovered")
        discoveredGlucoseMeters.append(glucoseMeter)
        print("glucose meter: \(glucoseMeter.name)")
        
        self.refresh()
    }
    
    // MARK: Table data source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return discoveredGlucoseMeters.count
        } else {
            return previouslySelectedGlucoseMeters.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as UITableViewCell
        
        if (indexPath.section == 0) {
            let peripheral = Array(self.discoveredGlucoseMeters)[indexPath.row]
            cell.textLabel!.text = peripheral.name
            cell.detailTextLabel!.text = peripheral.identifier.uuidString
        } else {
            let peripheral = Array(self.previouslySelectedGlucoseMeters)[indexPath.row]
            cell.textLabel!.text = peripheral.name
            cell.detailTextLabel!.text = peripheral.identifier.uuidString
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Discovered Glucose Meters"
        } else {
            return "Previously Connected Glucose Meters"
        }
    }
    
    //MARK: table delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAtIndexPath")
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.section == 0) {
            let glucoseMeter = Array(discoveredGlucoseMeters)[indexPath.row]
            self.peripheral = glucoseMeter
            self.addPreviouslySelectedGlucoseMeter(self.peripheral)
            self.didSelectDiscoveredGlucoseMeter(Array(self.discoveredGlucoseMeters)[indexPath.row])
        } else {
            let glucoseMeter = Array(previouslySelectedGlucoseMeters)[indexPath.row]
            self.peripheral = glucoseMeter
            self.didSelectPreviouslySelectedGlucoseMeter(Array(self.previouslySelectedGlucoseMeters)[indexPath.row])
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "segueToGlucoseMeter", sender: self)
    }
    
    func didSelectDiscoveredGlucoseMeter(_ peripheral:CBPeripheral) {
        print("ViewController#didSelectDiscoveredPeripheral \(peripheral.name)")
    }
    
    func didSelectPreviouslySelectedGlucoseMeter(_ peripheral:CBPeripheral) {
        print("ViewController#didSelectPreviouslyConnectedPeripheral \(peripheral.name)")
    }
    
    func addPreviouslySelectedGlucoseMeter(_ cbPeripheral:CBPeripheral) {
        var peripheralAlreadyExists: Bool = false
        
        for aPeripheral in self.previouslySelectedGlucoseMeters {
            if (aPeripheral.identifier.uuidString == cbPeripheral.identifier.uuidString) {
                peripheralAlreadyExists = true
            }
        }
        
        if (!peripheralAlreadyExists) {
            self.previouslySelectedGlucoseMeters.append(cbPeripheral)
        }
    }
    
    func getIPV4StringfromAddress(address: [Data]) -> String{
        
        let data = address.first! as NSData
        
        var ip1 = UInt8(0)
        data.getBytes(&ip1, range: NSMakeRange(4, 1))
        
        var ip2 = UInt8(0)
        data.getBytes(&ip2, range: NSMakeRange(5, 1))
        
        var ip3 = UInt8(0)
        data.getBytes(&ip3, range: NSMakeRange(6, 1))
        
        var ip4 = UInt8(0)
        data.getBytes(&ip4, range: NSMakeRange(7, 1))
        
        let ipStr = String(format: "%d.%d.%d.%d",ip1,ip2,ip3,ip4)
        
        return ipStr
    }
    
    func showFHIRServerAlertController() {
        let alert = UIAlertController(title: "Select FHIR server", message: "", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "fhirtest.uhn.ca", style: .default) { action in
            print("selected: fhirtest.uhn.ca")
            FHIR.fhirInstance.setFHIRServerAddress(address: "fhirtest.uhn.ca")
        })
        alert.addAction(UIAlertAction(title: self.fhirService.name, style: .default) { action in
            print("selected: bonjour-discovered fhir server")
            FHIR.fhirInstance.setFHIRServerAddress(address: self.fhirServiceIP!)
        })
        
        self.present(alert, animated: true)
    }
    
    @IBAction func discoverFHIRServersButtonAction(_ sender: Any) {
        self.browser.delegate = self
        print("searching for local FHIR servers")
        self.browser.searchForServices(ofType: "_http._tcp.", inDomain: "local")
    }
}

extension GlucoseMetersViewController: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("found service: \(service.name)")
        if(service.name.contains("fhir")) {
            self.browser.stop()
            print("resolving FHIR address")
            fhirService = service
            fhirService.delegate = self
            fhirService.resolve(withTimeout: 5.0)
        }
    }
}

extension GlucoseMetersViewController: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        fhirServiceIP = self.getIPV4StringfromAddress(address:sender.addresses!) + ":" + String(sender.port)
        print("resolved address: \(fhirServiceIP)")
        
        self.showFHIRServerAlertController()
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("didNotResolve")
    }
    
    func netServiceWillResolve(_ sender: NetService) {
        print("netServiceWillResolve")
    }
}
