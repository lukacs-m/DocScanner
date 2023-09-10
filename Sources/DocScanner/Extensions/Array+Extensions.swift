//
//  Array+Extensions.swift
//  DocScannerDemo
//
//  Created by martin on 04/09/2023.
//

import Foundation

extension Array where Element == String {
    /**
     Parses and extracts the card number from recognized text.
          
     - Returns: The card number as a string.
     */
    var parseCardNumber: String? {
        if let creditCardNumber = self.first(where: { $0.spaceNewLineTrimmed.isNumber &&
            $0.count >= 13 &&
            ["4", "5", "3", "6"].contains($0.first) }) {
            return creditCardNumber.newlineTrimmed
        }
        
        var creditCardNumber = self
            .map { $0.newlineTrimmed }
            .filter { !$0.contains("/") }
            .filter { $0.rangeOfCharacter(from: .letters) == nil && $0.count >= 4 }
            .joined(separator: " ")
        
        if creditCardNumber.spaceNewLineTrimmed.count < 13 ||
           !["4", "5", "3", "6"].contains(creditCardNumber.first) {
            return nil
        }
        
        if creditCardNumber.spaceNewLineTrimmed.count > 16 {
            creditCardNumber = String(creditCardNumber.spaceNewLineTrimmed.prefix(16))
        }
        return creditCardNumber
    }
}
