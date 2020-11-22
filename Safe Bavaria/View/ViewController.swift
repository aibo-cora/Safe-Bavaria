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
    let guidelinesAlways = ["Keep your distance", "Wear a mask", "Wash your hands", "Air rooms regularly"]
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
        
        var backgroundTaskID: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        
        DispatchQueue.global().async {
            backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "Find location and update UI") {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = UIBackgroundTaskIdentifier.invalid
            }
            
            self.startTimer()
            // End the task assertion.
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
        
        configureUI()
        Utility.configureSettings()
        
        NotificationCenter.default.addObserver(self, selector: #selector(userLocated(_:)), name: .UserLocated, object: nil)
        
        activityIndicator = ProgressIndicator(inview:self.view, loadingViewColor: UIColor(red: 1, green: 1, blue: 1, alpha: 1), indicatorColor: UIColor.black, message: "Gathering data...".localized())
            self.view.addSubview(activityIndicator!)
        if self.alertColorButtons.count == self.colorSchemes.count {
            for counter in 0..<self.alertColorButtons.count {
                self.alertColorButtons[counter].backgroundColor = self.colorSchemes[counter]
            }
        }
    }
    
    /// Setup UI components
    fileprivate func configureUI() {
        UIView.animate(withDuration: 1) {
            for counter in 0..<self.alertColorButtons.count {
                self.alertColorButtons[counter].alpha = 0.1
            }
        } completion: { (finished) in
            UIView.animate(withDuration: 1) {
                let guideline = NSMutableAttributedString()
                guideline.append(Utility.formatGuidelines(using: self.guidelinesAlways))

                self.guidelineTextView.isHidden = false
                self.guidelineTextView.attributedText = guideline
            }
        }
    }
    /// Every "timeInternal" (current = 10 minutes) the timer fires up the location manager to find user location.
    @objc func startTimer() {
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "com.location.services.timer", attributes: .concurrent))
        timer?.schedule(deadline: .now(), repeating: .seconds(timeInterval))
        timer?.setEventHandler { [unowned self] in
                Utility.configureLocationManager(manager: self.locationManager, delegate: self)
        }
        if #available(iOS 10.0, *) {
            timer?.activate()
        } else {
            timer?.resume()
        }
    }
    
    /// When the location manager delegate updates (returns) user location, this function continues with checking whether the user is in the region that is being monitored. If the user is in the region, the function calls an API that returns number of cases in the region from the server.
    /// - Parameter notification: notification that triggered this call.
    @objc func userLocated(_ notification: NSNotification) {
        dismiss(animated: true, completion: nil)
        print("Identifying region...")
        
        Utility.findLocationRegion(location: Utility.userLocation) { [unowned self]
            (germanState) in
            if let state = germanState {
                switch state {
                case self.region:
                    self.showProgress()
                    print("Retrieving data from server...")
                    Utility.getCasesData() { [unowned self]
                        cases, time, error  in
                        if error == nil {
                            if let cases = Double(cases) {
                                self.defineAlertLevel(using: cases, lastUpdated: time)
                            }
                        } else {
                            let alert = UIAlertController(title: "Server Error.".localized(), message: "Server did not respond, please try again later.".localized(), preferredStyle: .alert)
                            self.present(alert, animated: true) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                    self.dismiss(animated: true, completion: nil)
                                }
                            }
                        }
                    }
                default:
                    let alert = UIAlertController(title: "Out of bounds".localized(), message: "This region is not being monitored.".localized(), preferredStyle: .alert)
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    /// Call helper function to find out what the guidelines and current alert level are. If alert level changed, display a local notification. Update UI.
    /// - Parameters:
    ///   - cases: Number of cases return from the server.
    ///   - lastUpdated: Time stamp when the number of cases was updated last.
    func defineAlertLevel(using cases: Double, lastUpdated: String) {
        let (guidelines, currentAlertLevel) = Utility.getGuidelines(using: cases)
        
        if currentAlertLevel != Utility.alertLevel {
            Utility.postLocalNotification(message: "Alert Level Changed.".localized())
            Utility.alertLevel = currentAlertLevel
        }
        
        displayData(using: guidelines, time: lastUpdated)
    }
    
    /// Display activity indicator while the app is getting a response from the server and the app is locating the user.
    fileprivate func showProgress() {
        DispatchQueue.main.async {
            self.activityIndicator?.start()
        }
    }
    
    /// Update UI, if needed, to show current guidelines within app.
    /// - Parameter message: Current level guidelines.
    /// - Parameter lastUpdated: Time stamp of last updated batch of data.
    fileprivate func displayData(using message: String?, time lastUpdated: String) {
        DispatchQueue.main.async {
            self.activityIndicator?.stop()
            
            UIView.animate(withDuration: 1) {
                self.alertColorButtons[Utility.alertLevel.rawValue].alpha = 1
            } completion: { (finished) in
                UIView.animate(withDuration: 1) {
                    let attributedString = NSMutableAttributedString(attributedString: Utility.formatGuidelines(using: self.guidelinesAlways))
                    attributedString.append(NSAttributedString(string: "\n\n\nAdditional guidelines as of: ".localized(), attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .bold)]))
                    attributedString.append(NSAttributedString(string: lastUpdated, attributes: [.font: UIFont.italicSystemFont(ofSize: 20)]))
                    attributedString.append(NSAttributedString(string: "\n\n", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .regular)]))
                    
                    if var message = message?.localized() {
                        message = message.replacingOccurrences(of: "- ", with: "\t\u{2022}\t")
                        attributedString.append(NSAttributedString(string: message, attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .regular)]))
                    }
                    self.guidelineTextView.attributedText = attributedString
                }
            }
        }
    }

    deinit {
        timer?.cancel()
        timer = nil
    }
}

