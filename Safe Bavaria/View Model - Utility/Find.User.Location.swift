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
        case .notDetermined, .denied, .restricted:
            self.alertLocationAccessNeeded()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Utility.userLocation = locations.last
        NotificationCenter.default.post(name: .UserLocated, object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let alert = UIAlertController(title: "Error", message: "Could not find your location.", preferredStyle: .alert)
        present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
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
