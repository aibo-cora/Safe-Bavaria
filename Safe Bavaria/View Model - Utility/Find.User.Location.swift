//
//  Find.User.Location.swift
//  Safe Bavaria
//
//  Created by Yura on 11/11/20.
//

import UIKit
import Foundation
import CoreLocation

// This extension handles CLLocationManagerDelegate methods
extension ViewController {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            if CLLocationManager.locationServicesEnabled() {
                manager.requestAlwaysAuthorization()
            }
        case .authorizedAlways:
            if CLLocationManager.locationServicesEnabled() {
                manager.requestLocation()
            }
        case .denied, .restricted:
            self.alertLocationAccessNeeded()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Utility.userLocation = locations.last
        NotificationCenter.default.post(name: .UserLocated, object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let alert = UIAlertController(title: "Error".localized(), message: "Could not find your location.".localized(), preferredStyle: .alert)
        present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    /// Display an alert and a link to device settings to allow location tracking in case the user opted out permitting the app to locate device before.
    func alertLocationAccessNeeded() {
        let settingAppURL = URL(string: UIApplication.openSettingsURLString)!
        
        let alert = UIAlertController(title: "Need Location Access",
                                      message: "Please allow location tracking to accurately record visited country. This will not be shared with anyone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .default,
                                      handler: nil))
        alert.addAction(UIAlertAction(title: "Allow Location Access",
                                      style: .cancel,
                                      handler:
        { (action) in
            UIApplication.shared.open(settingAppURL, options: [:], completionHandler: nil)
        }))
        
        present(alert, animated: true)
    }
}
