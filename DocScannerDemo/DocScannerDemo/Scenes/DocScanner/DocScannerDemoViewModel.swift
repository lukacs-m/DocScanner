//
//  DocScannerDemoViewModel.swift
//
//
//  Created by martin on 01/09/2023.
//

import DocScanner
import Observation

@MainActor
@Observable
final class DocScannerDemoViewModel {
    var scanResponse: (any ScanResult)?
    var showScanner = false

    /// Pass this to `DocScanner(resultStream:)` to receive outcomes as an `AsyncStream`.
    let streamBox = ScanResultStreamBox()
    private var scanType: DocScanType = .document
    @ObservationIgnored private var streamTask: Task<Void, Never>?

    init() {
        // Demonstrates the AsyncStream channel (replaces the old Combine `.values`).
        streamTask = Task { [streamBox] in
            for await outcome in streamBox.stream {
                print("AsyncStream outcome: \(outcome)")
            }
        }
    }

    deinit {
        streamTask?.cancel()
    }

    var interpretor: ScanInterpreter {
        ScanInterpreter(type: scanType)
    }

    func startScan(for type: DocScanType = .document) {
        scanType = type
        showScanner.toggle()
    }

    /// Demonstrates the completion-closure channel.
    func handle(_ outcome: ScanOutcome) {
        print("Callback outcome: \(outcome)")
    }
}
