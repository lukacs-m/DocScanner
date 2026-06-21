//
//  ScanInterpreterError.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

/// Errors surfaced while interpreting a document scan.
///
/// Document interpretation uses typed throws so that a Vision failure is surfaced to
/// the caller instead of being silently swallowed to an empty result.
public enum ScanInterpreterError: Error, Sendable {
    /// The scanned page produced no usable `CGImage`.
    case noImage
    /// The Vision text-recognition request failed.
    case textRecognitionFailed(any Error)
}
