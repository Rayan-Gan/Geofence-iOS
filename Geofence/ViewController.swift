//
//  ViewController.swift
//  Geofence
//
//  Created by Rayan Gan on 28/09/2019.
//  Copyright © 2019 Settle. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SystemConfiguration.CaptiveNetwork

class ViewController: UIViewController {
    
    // MARK: - IB Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var geofenceStatusLabel: UILabel!
    
    // MARK: - Properties
    let locationManager = CLLocationManager()
    var wifiSSID = "-1"
    var enteredWiFiSSID = ""
    var inGeofenceArea = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLocationManager()
        setMapView()
        getConnectedWifiSSID()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        else if CLLocationManager.authorizationStatus() == .denied {
            print("Location services denied.")
        }
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IB Actions
    @IBAction func setGeofenceBtnTapped(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Geofence Setup", message: "Please enter a coordinate, radius, and WiFi SSID", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Latitude"
            textField.keyboardType = .decimalPad
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Longitude"
            textField.keyboardType = .decimalPad
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Radius"
            textField.keyboardType = .decimalPad
        }
        alert.addTextField { (textField) in
            textField.placeholder = "WiFi SSID"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let latitude = alert!.textFields![0].text!.isEmpty ? "0" : alert!.textFields![0].text!
            let latitudeDouble = Double(latitude)!
            let longitude = alert!.textFields![1].text!.isEmpty ? "0" : alert!.textFields![1].text!
            let longitudeDouble = Double(longitude)!
            let radius = alert!.textFields![2].text!.isEmpty ? "0" : alert!.textFields![2].text!
            let radiusDouble = Double(radius)!
            self.enteredWiFiSSID = alert!.textFields![3].text!
            self.verifyGeofence()
            
            self.setupData(coordinate: CLLocationCoordinate2DMake(latitudeDouble, longitudeDouble), radius: radiusDouble)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Helper Functions
    func setLocationManager() {
        locationManager.delegate = self
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    func setMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
    }
    func setupData(coordinate: CLLocationCoordinate2D, radius: Double) {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let title = "Geofence Area"
            let coordinate = coordinate
            let regionRadius = radius
            
            let region = CLCircularRegion(center: CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude), radius: regionRadius, identifier: title)
            locationManager.startMonitoring(for: region)
            
            let geofenceAnnotation = MKPointAnnotation()
            geofenceAnnotation.coordinate = coordinate
            geofenceAnnotation.title = title
            mapView.addAnnotation(geofenceAnnotation)
            
            let circle = MKCircle(center: coordinate, radius: regionRadius)
            mapView.add(circle)
        }
        else {
            print("System can't track regions")
        }
    }
    func getConnectedWifiSSID() {
        if let interfaces:CFArray = CNCopySupportedInterfaces() {
            for i in 0..<CFArrayGetCount(interfaces){
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
                if unsafeInterfaceData != nil {
                    let interfaceData = unsafeInterfaceData! as Dictionary!
                    for dictData in interfaceData! {
                        if dictData.key as! String == "SSID" {
                            self.wifiSSID = dictData.value as! String
                        }
                    }
                }
            }
        }
    }
    func verifyGeofence() {
        if inGeofenceArea || enteredWiFiSSID == wifiSSID {
            geofenceStatusLabel.text = "Inside"
        }
        else {
            geofenceStatusLabel.text = "Outside"
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        inGeofenceArea = true
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        inGeofenceArea = false
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        verifyGeofence()
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let geofenceAreaRenderer = MKCircleRenderer(overlay: overlay)
        geofenceAreaRenderer.strokeColor = UIColor.green
        geofenceAreaRenderer.lineWidth = 0.5
        return geofenceAreaRenderer
    }
}

