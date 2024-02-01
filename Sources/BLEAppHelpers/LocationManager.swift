//  LocationManager.swift
//  Created by Matt Gaidica on 1/30/24.

import Foundation
import MapKit
import CoreLocation

public class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published public var region = MKCoordinateRegion()
    private let locationManager = CLLocationManager()
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
    }
    
    public func updateRegionToCoordinate(_ coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
    }
}
