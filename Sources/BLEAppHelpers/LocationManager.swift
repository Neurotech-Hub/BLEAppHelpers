//  LocationManager.swift
//  Created by Matt Gaidica on 1/30/24.

import Foundation
import CoreLocation

// Make the class public
public class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // Make the published property public
    @Published public var location: CLLocation?
    
    // Make the initializer public
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Make the delegate method public
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}
