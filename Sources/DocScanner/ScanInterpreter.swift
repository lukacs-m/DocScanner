//
//  ScanInterpreter.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation
import Vision
import VisionKit

/**
 The `ScanInterpreter` actor provides document interpretation functionality for scanned documents and cards.
 It utilizes the Vision and VisionKit frameworks to extract text from scanned images and interprets the text to construct a `ScanResponse`.
 */
public actor ScanInterpreter: ScanInterpreting {
    private let type: DocScanType
    
    public init(type: DocScanType = .document) {
        self.type = type
    }
    
    /**
     Parses and interprets scanned document pages.
     
     - Parameter scans: A `VNDocumentCameraScan` object containing scanned document pages.
     
     - Returns: A `ScanResponse` that represents the interpretation of the scanned document.
     */
    public func parseAndInterpret(scans: VNDocumentCameraScan) async -> any ScanResult {
        switch type {
        case .card:
            return parseCard(scan: scans)
        default:
            return parseDocument(scans: scans)
        }
    }
}

// MARK: - Documents
private extension ScanInterpreter {
    func parseDocument(scans: VNDocumentCameraScan) -> any ScanResult {
        let scanPages = (0..<scans.pageCount).compactMap { pageNumber -> Page? in
            let image = scans.imageOfPage(at: pageNumber)
            guard let text = extractText(image: image)  else {
                return nil
            }
            
            return Page(pageNumber: pageNumber, image: image, text: text)
        }
        
        return ScannedDocument(title: scans.title, scannedPages: scanPages)
    }
}

// MARK: - Cards
 extension ScanInterpreter {
    /**
       Parses and interprets a scanned card.
       
       - Parameter scan: A `VNDocumentCameraScan` object containing a scanned card image.
       
       - Returns: A `ScanResponse` that represents the interpretation of the scanned card.
       */
     private func parseCard(scan: VNDocumentCameraScan) -> any ScanResult {
         let image = scan.imageOfPage(at: 0)
         guard let text = extractText(image: image) else {
             return CardDetails.empty
         }
         return ScanInterpreter.parseCardResults(for: text, and: image)
     }
    
    static func parseCardResults(for recognizedText: [String], and image: UIImage?) -> any ScanResult {
        var expiryDate: String?
        var name: String?
        var creditCardNumber: String?
        var cvv: String?
        if let parsedCard = recognizedText.parseCardNumber {
            creditCardNumber = parsedCard
        }
        for text in recognizedText {
            if let expiryDateString = text.parseExpiryDate {
                expiryDate = expiryDateString
            }
            
            if let parsedName = text.parseName {
                name = parsedName
            }
            
            if let parsedCVV = text.parseCVV(cardNumber: creditCardNumber) {
                cvv = parsedCVV
            }
        }
        
        return CardDetails(image: image,
                           numberWithDelimiters: creditCardNumber,
                           name: name,
                           expiryDate: expiryDate,
                           cvvNumber: cvv)
    }
}

// MARK: - Utils

private extension ScanInterpreter {
    /**
     Extracts recognized text from an image.
     
     - Parameter image: A `UIImage` containing text.
     
     - Returns: An array of recognized text strings, or `nil` if text extraction fails.
     */
    func extractText(image: UIImage?) -> [String]? {
        guard let cgImage = image?.cgImage else { return nil }
        
        var recognizedText = [String]()
        
        var textRecognitionRequest = VNRecognizeTextRequest()
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = type == .card ? false : true
        if type == .card {
            textRecognitionRequest.customWords = CardType.allCases.map { $0.rawValue } + ["Expiry Date"]
        }
        textRecognitionRequest = VNRecognizeTextRequest { request, _ in
            guard let results = request.results,
                  !results.isEmpty,
                  let requestResults = request.results as? [VNRecognizedTextObservation]
            else { return }
            recognizedText = requestResults.compactMap { observation in
                observation.topCandidates(1).first?.string
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
}
