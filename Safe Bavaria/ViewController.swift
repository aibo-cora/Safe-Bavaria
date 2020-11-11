//
//  ViewController.swift
//  Safe Bavaria
//
//  Created by Yura on 11/11/20.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        OperationQueue.main.addOperation { [weak self] in
            self?.displayData()
        }
    }
    
    func displayData() {
        let colorMessages = Utility.getCurrentStates()
        
        let alert = UIAlertController(title: "Current state in Bavaria - GREEN", message: colorMessages[0], preferredStyle: .alert)
        present(alert, animated: true) {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                self.dismiss(animated: true, completion: nil)
//            }
        }
    }
}

