//
//  Utility.swift
//  Safe Bavaria
//
//  Created by Yura on 11/11/20.
//

import Foundation

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
}
