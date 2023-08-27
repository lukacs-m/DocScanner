//
//  ScanInterpretor.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation
import Vision
import VisionKit
import NaturalLanguage
import RegexBuilder

public actor ScanInterpreter: ScanInterpreting {
    private let type: DocScanType
    private let ignoredWords: IgnoredWords?
    
    public init(type: DocScanType = .document) {
        self.type = type
        self.ignoredWords = ScanInterpreter.loadJson(filename: "ignoredWords")
    }
    
    public func parseAndInterpret(scans: VNDocumentCameraScan) async -> ScanResponse {
        switch type {
        case .card:
            return parseCard(scan: scans)
        case .document:
            return parseDocument(scans: scans)
        }
    }
}

// MARK: - Documents
private extension ScanInterpreter {
    func parseDocument(scans: VNDocumentCameraScan) -> ScanResponse {
        let scanPages = (0..<scans.pageCount).compactMap { pageNumber -> Page? in
            let image = scans.imageOfPage(at: pageNumber)
            guard let text = extractText(image: image)  else {
                return nil
            }
            
            return Page(pageNumber: pageNumber, image: image, text: text)
        }
        
        return ScannedDocument(scannedPages: scanPages)
    }
}

// MARK: - Cards
private extension ScanInterpreter {
    func parseCard(scan: VNDocumentCameraScan) -> ScanResponse {
        let image = scan.imageOfPage(at: 0)
        guard let text = extractText(image: image) else {
            return CardDetails.empty
        }
        return parseCardResults(for: text, and: image)
    }
    
    func parseCardResults(for recognizedText: [String], and image: UIImage) -> ScanResponse {
        var expiryDate: String?
        var name: String?
        var creditCardNumber: String?
        var cvv: String?
        if let parsedCard = parseCardNumber(from: recognizedText) {
            creditCardNumber = parsedCard
        }
        for text in recognizedText {
            if let expiryDateString = parseExpiryDate(from: text) {
                expiryDate = expiryDateString
            }
            
            if let parsedName = parseName(from: text) {
                name = parsedName
            }
            
            if let parsedCVV = parseCVV(from: text, and: creditCardNumber) {
                cvv = parsedCVV
            }
        }
        
        return CardDetails(image: image,
                           numberWithDelimiters: creditCardNumber,
                           name: name,
                           expiryDate: expiryDate,
                           cvvNumber: cvv)
    }
    
    func parseCardNumber(from infos: [String]) -> String? {
        if let creditCardNumber = infos.filter({ $0.spaceTrimmed.isNumber })
            .first(where: { $0.count >= 13 && ["4", "5", "3", "6"]
                .contains($0.first) }) {
            return creditCardNumber
        }
        
        var creditCardNumber = infos
            .filter { !$0.contains("/")}
            .filter { $0.rangeOfCharacter(from: .letters) == nil && $0.count >= 4 }
            .joined(separator: " ")
        
        if creditCardNumber.spaceTrimmed.count > 16 {
            creditCardNumber = String(creditCardNumber.spaceTrimmed.prefix(16))
        }
        return creditCardNumber
    }
    
    func parseExpiryDate(from text: String) -> String? {
        let numberRange = 5...7
        let components = text.components(separatedBy: "/")
        guard numberRange.contains(text.count), text.contains("/"),
              components.count == 2 else {
            return nil
        }
        for component in components {
            if !component.isNumber {
                return nil
            }
        }
        
        return text
    }
    
    func parseName(from text: String) -> String? {
        if let detectedName = naturalLanguageNameParser(from: text) {
            return detectedName
        }
        
        let wordsToAvoid = CardType.names + (ignoredWords?.words ?? [])
        
        guard !wordsToAvoid.contains(text.lowercased()),
              text.isUppercase,
              text.rangeOfCharacter(from: .decimalDigits) == nil,
              text.components(separatedBy: " ").count >= 2,
              text.nameRegexChecked else {
            return nil
        }
        
        return text
    }
    
    // CVV codes are a 3-digit number for Visa, Mastercard, and Discover cards, and a 4-digit number for Amex.
    func parseCVV(from text: String, and cardNumber: String?) -> String? {
        guard let cardNumber else {
            return nil
        }
        let type = CardType(number: cardNumber.spaceTrimmed)
        guard type == .visa || type == .masterCard || type == .amex, text.isNumber else {
            return nil
        }
        if type == .visa || type == .masterCard, text.count != 3 {
            return nil
        }
        if type == .amex, text.count != 4 {
            return nil
        }
        if cardNumber.contains(text) {
            return nil
        }
        return text
    }
}

// MARK: - Utils

private extension ScanInterpreter {
    func extractText(image: UIImage?) -> [String]? {
        guard let cgImage = image?.cgImage else { return nil }
        
        var recognizedText = [String]()
        
        var textRecognitionRequest = VNRecognizeTextRequest()
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection =  type == .card ? false : true
        if type == .card {
            textRecognitionRequest.customWords = CardType.allCases.map { $0.rawValue } + ["Expiry Date"]
        }
        textRecognitionRequest = VNRecognizeTextRequest() { (request, error) in
            guard let results = request.results,
                  !results.isEmpty,
                  let requestResults = request.results as? [VNRecognizedTextObservation]
            else { return }
            recognizedText = requestResults.compactMap { observation in
                return observation.topCandidates(1).first?.string
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([textRecognitionRequest])
            return recognizedText
        } catch {
            return nil
        }
    }
    
    func naturalLanguageNameParser(from text: String) -> String? {
        var currentName: String?
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
        let tags: [NLTag] = [.personalName]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: options) { tag, tokenRange in
            // Get the most likely tag, and print it if it's a named entity.
            if let tag = tag,
               tags.contains(tag) {
                print("\(text[tokenRange]): \(tag.rawValue)")
                currentName = String(text[tokenRange])
            }
            
            return true
        }
        
        return currentName
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
}
