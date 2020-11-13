//
//  ProgressIndicator.swift
//  Safe Bavaria
//
//  Created by Yura on 11/13/20.
//

import Foundation
import UIKit

class ProgressIndicator: UIView {

    var indicatorColor: UIColor
    var loadingViewColor: UIColor
    var loadingMessage: String
    var messageFrame = UIView()
    var activityIndicator = UIActivityIndicatorView()

    init(inview: UIView, loadingViewColor: UIColor, indicatorColor: UIColor, message: String) {
        self.indicatorColor = indicatorColor
        self.loadingViewColor = loadingViewColor
        self.loadingMessage = message
        super.init(frame: CGRect(x: inview.frame.midX - 100, y: inview.frame.midY, width: 200, height: 50))
        initalizeCustomIndicator()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initalizeCustomIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.tintColor = indicatorColor
        activityIndicator.hidesWhenStopped = true
        activityIndicator.frame = CGRect(x: self.bounds.origin.x + 6, y: 0, width: 20, height: 50)
        
        let strLabel = UILabel(frame:CGRect(x: self.bounds.origin.x + 30, y: 0, width: self.bounds.width - (self.bounds.origin.x + 30) , height: 50))
        strLabel.text = loadingMessage
        strLabel.adjustsFontSizeToFitWidth = true
        strLabel.textColor = UIColor.black
        
        messageFrame.frame = self.bounds
        messageFrame.layer.cornerRadius = 15
        messageFrame.backgroundColor = loadingViewColor
        messageFrame.alpha = 0.8
        messageFrame.addSubview(activityIndicator)
        messageFrame.addSubview(strLabel)
    }

    func  start() {
        //check if view is already there or not..if again started
        if !self.subviews.contains(messageFrame) {

            activityIndicator.startAnimating()
            self.addSubview(messageFrame)

        }
    }

    func stop() {
        if self.subviews.contains(messageFrame) {
            activityIndicator.stopAnimating()
            messageFrame.removeFromSuperview()

        }
    }
}
