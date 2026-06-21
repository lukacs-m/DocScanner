//
//  ScanInterpreter.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import UIKit
import Vision
import VisionKit

/**
 The `ScanInterpreter` interprets scanned documents and cards.

 It is a `Sendable` value type holding only an immutable configuration, so it needs no actor
 isolation. Heavy text recognition is pushed off the caller's executor via `@concurrent`,
 using the modern Swift-native Vision API (`RecognizeTextRequest`).
 */
public struct ScanInterpreter: ScanInterpreting {
    private let type: DocScanType

    public init(type: DocScanType = .document) {
        self.type = type
    }

    public func interpret(scan: VNDocumentCameraScan) async throws(ScanInterpreterError) -> any ScanResult {
        switch type {
        case .card:
            return try await parseCard(scan: scan)
        case .document:
            return try await parseDocument(scan: scan)
        }
    }

    public func interpretCard(from recognizedText: [String], image: UIImage?) async -> any ScanResult {
        parseCardResults(for: recognizedText, image: image)
    }

    public func interpret(recognizedStrings: [String]) async -> any ScanResult {
        GenericData(scannedData: recognizedStrings)
    }
}

// MARK: - Documents

private extension ScanInterpreter {
    func parseDocument(scan: VNDocumentCameraScan) async throws(ScanInterpreterError) -> any ScanResult {
        var scannedPages: [Page] = []
        for pageNumber in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: pageNumber)
            do {
                let text = try await extractText(from: image)
                guard !text.isEmpty else { continue }
                scannedPages.append(Page(pageNumber: pageNumber, image: image, text: text))
            } catch .noImage {
                continue // skip pages without a usable image; propagate genuine failures
            }
        }
        return ScannedDocument(title: scan.title, scannedPages: scannedPages)
    }
}

// MARK: - Cards

private extension ScanInterpreter {
    func parseCard(scan: VNDocumentCameraScan) async throws(ScanInterpreterError) -> any ScanResult {
        let image = scan.imageOfPage(at: 0)
        let text = try await extractText(from: image)
        return parseCardResults(for: text, image: image)
    }

    func parseCardResults(for recognizedText: [String], image: UIImage?) -> any ScanResult {
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

// MARK: - Text recognition

private extension ScanInterpreter {
    @concurrent
    func extractText(from image: UIImage) async throws(ScanInterpreterError) -> [String] {
        guard let cgImage = image.cgImage else {
            throw .noImage
        }

        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = type != .card
        if type == .card {
            request.customWords = CardType.names + ["Expiry Date"]
        }

        do {
            let observations = try await request.perform(on: cgImage)
            return observations.compactMap { $0.topCandidates(1).first?.string }
        } catch {
            throw .textRecognitionFailed(error)
        }
    }
}
