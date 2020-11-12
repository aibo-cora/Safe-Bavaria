//
//  Utility.swift
//  Safe Bavaria
//
//  Created by Yura on 11/11/20.
//

import UIKit
import Foundation
import CoreLocation

/// This is a class with static functions that acts as the View Model middleman between UI and model.
class Utility {
    /// Decodes data into a dictionary with readable messages and rules.
    /// - Returns: Dictionary that contains relevant information about each state of the current alert level.
    static func getCurrentStates() -> [Int:String] {
        var colorMessages: [Int:String] = [:]
        
        if let jsonData = Utility.getDataFromDatasource() {
            let decoder = JSONDecoder()
            
            do {
                colorMessages = try decoder.decode([Int:String].self, from: jsonData)
            } catch {
                
            }
        }
        return colorMessages
    }
    
    /// Retrieve data from a local file or a network source.
    /// - Returns: Optional Data object in case there is an error in retrieval.
    static func getDataFromDatasource() -> Data? {
        
        guard let filePath = Bundle.main.url(forResource: "jsonData", withExtension: nil) else { return nil }
        
        return try? Data(contentsOf: filePath)
    }
    
    /// Configure parameters for the location manager. Set delegate and request authorization to use location services
    /// - Parameters:
    ///   - manager: Location manager to configure.
    ///   - delegate: View that delegates tasks. Delegate methods implemented in "Find.User.Location.swift"
    static func configureLocationManager(manager: CLLocationManager, delegate: UIViewController & CLLocationManagerDelegate) {
        
        manager.allowsBackgroundLocationUpdates = true
        manager.delegate = delegate
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if CLLocationManager.locationServicesEnabled() {
                manager.requestLocation()
            }
        default:
            manager.requestWhenInUseAuthorization()
        }
    }
    
    static var userLocation: CLLocation?
    
    /// Reverse geocode the last reported location of the user to find the region.
    /// - Parameter location: Last known location of the user.
    static func findLocationRegion(location: CLLocation?, completion: @escaping (String?) -> Void) {
        if let location = location {
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                if error == nil {
                    if let firstLocation = placemarks?.first {
                        completion(firstLocation.administrativeArea)
                    }
                }
            }
        }
    }
    
    /// Retrieve number of cases in Bavaria per 100,000 in the last 7 days.
    /// - Parameter handler: After the responses is received, handler will display data on main View
    static func getCasesData(handler: @escaping (String) -> Void ) {
        handler("Testing...")
    }
}
