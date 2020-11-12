//
//  ViewController.swift
//  Safe Bavaria
//
//  Created by Yura on 11/11/20.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    /// How often, in secods, the app checks for updates
    let timeInterval = 600
    /// Contact tracing region
    let region = "Bavaria"
    
    var timer: DispatchSourceTimer?
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        OperationQueue.main.addOperation {
            self.startTimer()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(userLocated(_:)), name: .UserLocated, object: nil)
    }
    
    @objc func userLocated(_ notification: NSNotification) {
        Utility.findLocationRegion(location: Utility.userLocation) { (germanState) in
            if let state = germanState {
                switch state {
                case self.region:
                    Utility.getCasesData() { cases in
                        self.displayData()
                    }
                default:
                    let alert = UIAlertController(title: "Out of bounds", message: "This region is not being monitored.", preferredStyle: .alert)
                    self.present(alert, animated: true) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func displayData() {
        let colorMessages = Utility.getCurrentStates()
        
        let alert = UIAlertController(title: "Current state in Bavaria - GREEN", message: colorMessages[0], preferredStyle: .alert)
        present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func startTimer() {
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "com.location.services.timer", attributes: .concurrent))
        
        timer?.schedule(deadline: .now(), repeating: .seconds(timeInterval))
        timer?.setEventHandler {
            Utility.configureLocationManager(manager: self.locationManager, delegate: self)
        }
        if #available(iOS 10.0, *) {
            timer?.activate()
        } else {
            timer?.resume()
        }
    }
    
    func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    deinit {
        stopTimer()
    }
}

