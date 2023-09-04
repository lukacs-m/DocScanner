//
//  String+Extensions.swift
//  DocScannerDemo
//
//  Created by martin on 26/08/2023.
//

import Foundation
import NaturalLanguage
import RegexBuilder

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
    
    var spaceNewLineTrimmed: String {
     self.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
    
    var newlineTrimmed: String {
     self.replacingOccurrences(of: "\n", with: "")
    }
    
    var fullRange: NSRange {
        NSRange(location: 0, length: count)
    }
    
    var nameRegexChecked: Bool {
        if #available(iOS 16, *) {
            let regex = Regex {
                Optionally {
                    Repeat(2...3) {
                        CharacterClass(
                            ("A"..."Z")
                        )
                    }
                    Optionally {
                        "."
                    }
                }
                
                Repeat(3...24) {
                    CharacterClass(
                      .anyOf("'"),
                      ("A"..."Z")
                    )
                  }
                Optionally {
                       "."
                     }
                One(.whitespace)
                  Repeat(3...23) {
                    CharacterClass(
                      .anyOf("'"),
                      ("A"..."Z"),
                      .whitespace
                    )
                  }
                Optionally {
                   "."
                 }
            }
            return self.contains(regex)
        } else {
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
    
    /**
     Parses and extracts the expiry date from recognized text.
          
     - Returns: The expiry date as a string.
     */
    var parseExpiryDate: String? {
        let components = self.components(separatedBy: "\n")
            .filter { $0.contains("/") }
        guard let expiryDate = components.first else {
            return nil
        }
        
        let numberRange = 5...7
        let dateElements = expiryDate.components(separatedBy: "/")
        guard numberRange.contains(expiryDate.count),
        dateElements.count == 2 else {
            return nil
        }
        for component in dateElements where !component.isNumber {
            return nil
        }
        
        return expiryDate
    }
    
    /**
     Parses and extracts the cardholder's name from recognized text.
          
     - Returns: The cardholder's name as a string.
     */
    var parseName: String? {
        let ignoredWords: IgnoredWords? = Self.loadJson(filename: "ignoredWords")
        
        let wordsToAvoid = CardType.names + (ignoredWords?.words ?? [])
        
        guard !self.lowercased().contains(wordsToAvoid),
              !self.contains("\n"),
              self.isUppercase,
              self.rangeOfCharacter(from: .decimalDigits) == nil,
              self.components(separatedBy: " ").count >= 2,
              self.nameRegexChecked else {
            return nil
        }
        
        return self
    }
    
    /**
     Uses Natural Language Processing (NLP) to extract a personal name from text.
          
     - Returns: The detected name as a string, or `nil` if no name is detected.
     */
    var naturalLanguageNameParser: String? {
        var currentName: String?
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = self
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
        let tags: [NLTag] = [.personalName]
        
        tagger.enumerateTags(in: self.startIndex..<self.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: options) { tag, tokenRange in
            if let tag = tag,
               tags.contains(tag) {
                currentName = String(self[tokenRange])
            }
            
            return true
        }
        
        return currentName
    }
    
    /**
     Parses and extracts the CVV (Card Verification Value) from recognized text.
     CVV codes are a 3-digit number for Visa, Mastercard, and Discover cards, and a 4-digit number for Amex.
     
     - Parameter text: The recognized text string.
     - Parameter cardNumber: The card number for validation.
     
     - Returns: The CVV as a string.
     */
     func parseCVV(cardNumber: String?) -> String? {
         let components = self.components(separatedBy: "\n")
             .filter { !$0.contains("/") }
         guard let cardNumber, let stringToParse = components.first else {
            return nil
        }
        let type = CardType(number: cardNumber.spaceNewLineTrimmed)
         guard type == .visa || type == .masterCard || type == .amex, stringToParse.isNumber else {
            return nil
        }
        if type == .visa || type == .masterCard, stringToParse.count != 3 {
            return nil
        }
        if type == .amex, stringToParse.count != 4 {
            return nil
        }
        if cardNumber.contains(stringToParse) {
            return nil
        }
        return stringToParse
    }
    
    static func loadJson<T: Decodable>(filename fileName: String) -> T? {
        if let url = Bundle.module.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }
    
    func contains(_ strings: [String]) -> Bool {
        strings.contains { contains($0) }
    }
}
