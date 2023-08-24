//
//  ScanInterpretor.swift
//  
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation
import Vision
import VisionKit

public actor ScanInterpretor: ScanInterpreting {
   private let type: DocScanType

    public init(type: DocScanType = .document) {
        self.type = type
    }

    public func parseAndInterprete(scans: VNDocumentCameraScan) async -> ScanResponse {
        switch type {
        case .card:
            return parseCard(scan: scans)
        case .document:
            return parseDocument(scans: scans)
        }
    }

    func parseCard(scan: VNDocumentCameraScan) -> ScanResponse {
        let image = scan.imageOfPage(at: 0)
        guard let text = extractText(image: image) else {
            return CardDetails.empty
        }
        return parseCardResults(for: text, and: image)
    }


    //todo revenir dessus pour parse chque imgae et retouenr une fois finis
    func parseDocument(scans: VNDocumentCameraScan) -> ScanResponse {
        let scanPages = (0..<scans.pageCount).compactMap { pageNumber -> Page? in
            let image = scans.imageOfPage(at: pageNumber)
            guard let text = extractText(image: image)  else {
                return nil
            }

           return Page(pageNumber: pageNumber, image: image, text: text)
        }
//        let pageText = scanPages.map { page -> String in
//            let handler = VNImageRequestHandler(cgImage: page.image, options: [:])
//            do {
//                try handler.perform([page.request])
//                guard let observations = page.request.results else {
//                    return ""
//                }
//                return observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
//            } catch{
//                print(error)
//                return ""
//            }
//        }

        return ScannedDocument(scannedPages: scanPages)
    }

    func extractText(image: UIImage?) -> [String]? {
        guard let cgImage = image?.cgImage else { return nil }

        var recognizedText = [String]()

        var textRecognitionRequest = VNRecognizeTextRequest()
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
//        textRecognitionRequest.customWords = CardType.allCases.map { $0.rawValue } + ["Expiry Date"]
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
            print(error)
            return nil
        }
    }

    func parseCardResults(for recognizedText: [String], and image: UIImage) -> ScanResponse {
        // Credit Card Number
        let creditCardNumber = recognizedText.first(where: { $0.count >= 14 && ["4", "5", "3", "6"].contains($0.first) })

        // Expiry Date
        let expiryDateString = recognizedText.first(where: { $0.count > 4 && $0.contains("/") })
        let expiryDate = expiryDateString?.filter({ $0.isNumber || $0 == "/" })

        // Name
        let ignoreList = ["GOOD THRU", "GOOD", "THRU", "Gold", "GOLD", "Standard", "STANDARD", "Platinum", "PLATINUM", "WORLD ELITE", "WORLD", "ELITE", "World Elite", "World", "Elite"]
        let wordsToAvoid = [creditCardNumber, expiryDateString] +
            ignoreList +
            CardType.allCases.map { $0.rawValue } +
            CardType.allCases.map { $0.rawValue.lowercased() } +
            CardType.allCases.map { $0.rawValue.uppercased() }
        let name = recognizedText.filter({ !wordsToAvoid.contains($0) }).last

        return CardDetails(image: image, numberWithDelimiters: creditCardNumber, name: name, expiryDate: expiryDate)
    }
}
