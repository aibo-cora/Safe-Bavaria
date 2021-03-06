//
//  AppDelegate.swift
//  Safe Bavaria
//
//  Created by Yura on 11/11/20.
//

import UIKit
import BackgroundTasks
import CoreLocation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var locationManager = CLLocationManager()
    var window: UIWindow?
    let taskID = "com.safe.bavaria.refresh"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: DispatchQueue.global(qos: .utility)) { (task) in
            self.handleBackgroudRefresh(task: task as! BGAppRefreshTask)
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleBackgroundRefresh()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    // MARK: Background Mode
    fileprivate func handleBackgroudRefresh(task: BGAppRefreshTask) {
        print("Background refresh started...")
        
        let queue = OperationQueue.main
        queue.maxConcurrentOperationCount = 1
        queue.addOperation { [unowned self] in
            print("Operation added to queue...")
            Utility.configureLocationManager(manager: self.locationManager, delegate: self)
        }
        queue.operations.last?.completionBlock = {
            print("Operation completion block...")
            task.setTaskCompleted(success: true)
        }
        
        task.expirationHandler = {
            print("Expiration handler...")
            queue.cancelAllOperations()
            task.setTaskCompleted(success: false)
        }
        scheduleBackgroundRefresh()
    }
    
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task scheduled...")
        } catch {
            print("Could not schedule app refresh: \(error.localizedDescription)")
        }
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if CLLocationManager.locationServicesEnabled() {
                manager.requestLocation()
            }
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("User located (background)...")
        Utility.userLocation = locations.last
        NotificationCenter.default.post(name: .UserLocated, object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error.localizedDescription)")
    }
}
