//
//  ViewController.swift
//  Safe Bavaria
//
//  Created by Yura on 11/11/20.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var alertColorButtons: [AlertColorButton]!
    @IBOutlet weak var guidelineTextView: UITextView!
    
    let colorSchemes: [UIColor] = [
        UIColor(red: 0, green: 1, blue: 0, alpha: 1),       // Green
        UIColor(red: 1, green: 1, blue: 0, alpha: 1),       // Yellow
        UIColor(red: 1, green: 0, blue: 0, alpha: 1),       // Red
        UIColor(red: 128/255, green: 0, blue: 0, alpha: 1)  // Dark Red
    ]
    
    /// How often, in secods, the app checks for updates
    let timeInterval = 600
    /// Region to monitor
    let region = "Bavaria"
    
    var timer: DispatchSourceTimer?
    let locationManager = CLLocationManager()
    var activityIndicator: ProgressIndicator?
    
    //MARK: Application Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        OperationQueue.main.addOperation {
            self.startTimer()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(userLocated(_:)), name: .UserLocated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showProgress(_:)), name: .ShowProgress, object: nil)
        
        activityIndicator = ProgressIndicator(inview:self.view, loadingViewColor: UIColor(red: 1, green: 1, blue: 1, alpha: 1), indicatorColor: UIColor.black, message: "Gathering data...")
            self.view.addSubview(activityIndicator!)
    }
    
    /// When the location manager delegate updates (returns) user location, this function continues with checking whether the user is in the region that is being monitored. If the user is in the region, the function calls an API that returns number of cases in the region from a server.
    /// - Parameter notification: notification that triggered this call.
    @objc func userLocated(_ notification: NSNotification) {
        Utility.findLocationRegion(location: Utility.userLocation) { (germanState) in
            if let state = germanState {
                switch state {
                case self.region:
                    Utility.getCasesData() { cases, time, error  in
                        if error == nil {
                            if let cases = Double(cases) {
                                self.defineAlertLevel(using: cases, lastUpdated: time)
                            }
                        } else {
                            let alert = UIAlertController(title: "Server Error.", message: "Server did not respond, please try again later.", preferredStyle: .alert)
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
    
    func defineAlertLevel(using cases: Double, lastUpdated: String) {
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
        
        if currentAlertLevel != Utility.alertLevel {
            notifyUser(with: userMessage)
            Utility.alertLevel = currentAlertLevel
        }
        
        displayData(using: userMessage)
    }
    
    @objc fileprivate func showProgress(_ notification: NSNotification) {
        DispatchQueue.main.async {
            self.activityIndicator?.start()
        }
    }
    
    /// Update UI, if needed, to show current guidelines within app.
    /// - Parameter message: Current level guidelines.
    fileprivate func displayData(using message: String?) {
        DispatchQueue.main.async {
            self.activityIndicator?.stop()
            
            if self.alertColorButtons.count == self.colorSchemes.count {
                for counter in 0..<self.alertColorButtons.count {
                    self.alertColorButtons[counter].backgroundColor = self.colorSchemes[counter]
                }
            }
            
            UIView.animate(withDuration: 1) {
                for counter in 0..<self.alertColorButtons.count {
                    self.alertColorButtons[counter].alpha = 0.1
                }
            } completion: { (finished) in
                UIView.animate(withDuration: 1) {
                    self.alertColorButtons[Utility.alertLevel.rawValue].alpha = 1
                    
                    let guideline = NSMutableAttributedString(string: "Current health related guidelines in Bavaria:", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .semibold)])
                    guideline.append(NSAttributedString(string: "\n\n\n"))
                    guideline.append(NSAttributedString(string: message ?? "", attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .regular)]))
                    
                    self.guidelineTextView.isHidden = false
                    self.guidelineTextView.attributedText = guideline
                }
            }
        }
    }
    
    /// Alert level has changed. Display a notification.
    /// - Parameter message: Current level guidelines.
    fileprivate func notifyUser(with message: String?) {
        print("Alert level has changed...")
    }
    
    /// Every "timeInternal" (current = 10 minutes) the timer fires up the location manager to find user location.
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

