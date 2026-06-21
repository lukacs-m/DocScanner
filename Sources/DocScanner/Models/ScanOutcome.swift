//
//  ScanOutcome.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

/// The result of a scan, delivered through every channel a scanner exposes
/// (completion closure, `@Binding`, and `AsyncStream`).
///
/// `cancelled` is a first-class case rather than an overloaded `nil`/`.success(nil)`,
/// so callers can distinguish "the user dismissed the camera" from "a scan produced
/// no result".
public enum ScanOutcome: Sendable {
    /// A scan completed and produced a result.
    case scanned(any ScanResult)
    /// The user dismissed the scanner without scanning.
    case cancelled
    /// The scan failed with an error.
    case failed(any Error)
}
