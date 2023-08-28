//
//  String+Extensions.swift
//  DocScannerDemo
//
//  Created by martin on 26/08/2023.
//

import Foundation

extension String {
    var isLowercase: Bool {
        self == self.lowercased()
    }
    
    var isUppercase: Bool {
        self == self.uppercased()
    }
    
    var isNumber: Bool {
        self.range(
            of: "^[0-9]*$",
            options: .regularExpression) != nil
    }
    
    var spaceTrimmed: String {
        self.replacingOccurrences(of: " ", with: "")
    }
    
    var fullRange: NSRange {
        NSRange(location: 0, length: count)
    }
    
    var nameRegexChecked: Bool {
        let namePatternCheck = #"""
        ^[A-Z']{1,24}\.?\s[A-Z][A-Z'\s]{3,23}\.?$
        """#
        if let regex = try? NSRegularExpression(pattern: namePatternCheck,
                                                options: .allowCommentsAndWhitespace),
           regex.matches(in: self).isEmpty {
            return false
        }
        return true
    }
}
