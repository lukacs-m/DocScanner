//
//  ScannerModel.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Observation

/// A high-level, `@Observable` convenience for consuming scan results in SwiftUI.
///
/// It owns a ``ScanResultStreamBox`` (stable across SwiftUI view updates), consumes the
/// stream internally, and republishes the latest result as observable state. Pass
/// ``streamBox`` to a scanner's `resultStream:` parameter and observe ``latest`` /
/// ``lastOutcome`` in your view:
///
/// ```swift
/// @State private var scanner = ScannerModel()
/// // ...
/// DocScanner(resultStream: scanner.streamBox)
/// // observe scanner.latest
/// ```
@MainActor
@Observable
public final class ScannerModel {
    /// The most recent successfully scanned result.
    public private(set) var latest: (any ScanResult)?
    /// The most recent outcome, including cancellation and failure.
    public private(set) var lastOutcome: ScanOutcome?

    /// Pass this to a scanner's `resultStream:` parameter.
    @ObservationIgnored public let streamBox = ScanResultStreamBox()
    @ObservationIgnored private var consumerTask: Task<Void, Never>?

    public init() {
        let stream = streamBox.stream
        consumerTask = Task { [weak self] in
            for await outcome in stream {
                self?.ingest(outcome)
            }
        }
    }

    private func ingest(_ outcome: ScanOutcome) {
        lastOutcome = outcome
        if case let .scanned(result) = outcome {
            latest = result
        }
    }

    deinit {
        consumerTask?.cancel()
        streamBox.finish()
    }
}
