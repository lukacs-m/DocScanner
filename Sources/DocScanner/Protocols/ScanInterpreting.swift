//
//  ScanInterpreting.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import UIKit
import VisionKit

/// Interprets scanned input into a ``ScanResult``.
///
/// Conformers are `Sendable` (not necessarily actors): the protocol no longer mandates a
/// specific isolation, so an interpreter can be a value type, a `@MainActor` class, or an
/// actor. Methods are statically typed per input kind — there is no `Any`-based entry point
/// and no runtime downcasting at the call sites.
///
/// Default implementations are provided for all three methods, so a custom interpreter only
/// implements the one(s) for the scanner(s) it feeds.
public protocol ScanInterpreting: Sendable {
    /// Interpret a multi-page document/card scan from `VNDocumentCameraViewController`.
    func interpret(scan: VNDocumentCameraScan) async throws(ScanInterpreterError) -> any ScanResult

    /// Interpret already-recognized text lines from a live card scan.
    func interpretCard(from recognizedText: [String], image: UIImage?) async -> any ScanResult

    /// Interpret arbitrary recognized strings (the live scanner's `.custom` path).
    func interpret(recognizedStrings: [String]) async -> any ScanResult
}

public extension ScanInterpreting {
    func interpret(scan: VNDocumentCameraScan) async throws(ScanInterpreterError) -> any ScanResult {
        GenericData(scannedData: [])
    }

    func interpretCard(from recognizedText: [String], image: UIImage?) async -> any ScanResult {
        await interpret(recognizedStrings: recognizedText)
    }

    func interpret(recognizedStrings: [String]) async -> any ScanResult {
        GenericData(scannedData: recognizedStrings)
    }
}
