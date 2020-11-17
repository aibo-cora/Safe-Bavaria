//
//  Utility.swift
//  Safe Bavaria
//
//  Created by Yura on 11/11/20.
//

import UIKit
import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON

/// This is a class with static functions that acts as the View Model middleman between UI and model.
class Utility {
    /// Request user authorization to display local notifications.
    static func configureSettings() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
            
            if let error = error {
                print(error.localizedDescription)
            }
            
            // Enable or disable features based on the authorization.
        }
    }
    
    /// If the user authorized notifications, display a local notification which  informs the user that new guidelines are in effect.
    static func postLocalNotification() {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            guard (settings.authorizationStatus == .authorized) ||
                  (settings.authorizationStatus == .provisional) else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Alert Level Changed"
            content.body = "View new guidelines."
            content.sound = UNNotificationSound.default
            
            if settings.alertSetting == .enabled {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                // Create the request
                let uuidString = UUID().uuidString
                let request = UNNotificationRequest(identifier: uuidString,
                            content: content, trigger: trigger)

                // Schedule the request with the system.
                center.add(request) { (error) in
                   if error != nil {
                      // Handle any errors.
                   }
                }
            } else {
                // Schedule a notification with a badge and sound.
                
            }
        }
    }
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
    static func configureLocationManager(manager: CLLocationManager, delegate: CLLocationManagerDelegate?) {
        
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
    static var alertLevel = AlertLevel.Green
    
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
    /// - Parameter handler: After the responses is received, handler will hand off # of cases, date of the last update and error (if any) to the View for display.
    static func getCasesData(handler: @escaping (String, String, Error?) -> Void ) {
        if let queryURL = URL(string: "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_Landkreisdaten/FeatureServer/0/query?where=1%3D1&outFields=BL,BL_ID,county,last_update,cases7_per_100k,cases7_bl_per_100k&outSR=4326&f=json") {
            
            AF.request(queryURL, method: .get).responseJSON { (response) in
                switch response.result {
                case .success(let jsonData):
                    let data = JSON(jsonData)
                    
                    dataLoop: for feature in data["features"] {
                        featureLoop: for (key,value) in feature.1 {
                            if key == "attributes" {
                                if value["BL"] == "Bayern" {
                                    handler(value["cases7_bl_per_100k"].stringValue, value["last_update"].stringValue, nil)
                                    break dataLoop
                                }
                            }
                        }
                    }
                case .failure(let error):
                    handler("", "", error)
                }
            }
        }
    }
    
    /// Identify alert level based on received number of cases
    /// - Parameter cases: Number of cases returned from the server.
    /// - Returns: Guidelines that match the current alert level and current alert level.
    static func getGuidelines(using cases: Double) -> (String?, AlertLevel) {
        let colorMessages = Utility.getCurrentStates()
        var currentAlertLevel = AlertLevel.Green
        var userMessage:String?
        
        switch cases {
        case 0...34:
            currentAlertLevel = .Green
            userMessage = colorMessages[0]
        case 36...50:
            currentAlertLevel = .Yellow
            userMessage = colorMessages[1]
        case 51...99:
            currentAlertLevel = .Red
            userMessage = colorMessages[2]
        default:
            currentAlertLevel = .DarkRed
            userMessage = colorMessages[3]
        }
        
        return (userMessage, currentAlertLevel)
    }
}
