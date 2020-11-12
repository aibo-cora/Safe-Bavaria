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
                    Utility.getCasesData() { cases, time, error  in
                        if error == nil {
                            if let cases = Double(cases) {
                                self.displayData(using: cases, lastUpdated: time)
                            }
                        } else {
                            let alert = UIAlertController(title: "Server Error.", message: "Server does not respond, please try again later.", preferredStyle: .alert)
                            self.present(alert, animated: true) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                    self.dismiss(animated: true, completion: nil)
                                }
                            }
                        }
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
    
    func displayData(using cases: Double, lastUpdated: String) {
        let colorMessages = Utility.getCurrentStates()
        var currentState: String?
        var currentAlertLevel = ""
        
        switch cases {
        case 0...34:
            currentState = colorMessages[0]
            currentAlertLevel = "GREEN"
        case 36...50:
            currentState = colorMessages[1]
            currentAlertLevel = "YELLOW"
        case 51...99:
            currentState = colorMessages[2]
            currentAlertLevel = "RED"
        default:
            currentState = colorMessages[3]
            currentAlertLevel = "DARK RED"
        }
        
        let alert = UIAlertController(title: currentAlertLevel, message: currentState, preferredStyle: .alert)
        present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                self.dismiss(animated: true, completion: nil)
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

