//
//  AppDelegate.swift
//  Safe Bavaria
//
//  Created by Yura on 11/11/20.
//

import UIKit
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

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

    // MARK: Background Mode
    fileprivate func handleBackgroudRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()
        print("background refresh performing tasks...")
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperation {
            
        }
        queue.operations.last?.completionBlock = {
            task.setTaskCompleted(success: true)
        }
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }
    }
    
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
}

