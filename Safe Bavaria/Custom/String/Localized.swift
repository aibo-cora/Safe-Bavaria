//
//  Localized.swift
//  Safe Bavaria
//
//  Created by Yura on 11/12/20.
//

import Foundation

extension String {
    
    /// Returns a string based on localized settings
    /// - Parameter comment: comment.
    /// - Returns: localized string.
    func localized(withComment comment: String? = nil) -> String {
        return NSLocalizedString(self, comment: comment ?? "")
    }

}
