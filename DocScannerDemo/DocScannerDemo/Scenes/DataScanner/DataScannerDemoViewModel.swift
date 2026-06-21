//
//  DataScannerDemoViewModel.swift
//  DocScannerDemo
//
//  Created by martin on 04/09/2023.
//

import DocScanner
import Foundation
import Observation

@MainActor
@Observable
final class DataScannerDemoViewModel {
    var scanResponse: (any ScanResult)?
    var showScanner = false
    var scanning = false
    var applyRegionOfInterest = false
    var automaticDismiss = true
    var regionOfInterest: CGRect?

    /// Pass this to `DataScanner(resultStream:)` to receive outcomes as an `AsyncStream`.
    let streamBox = ScanResultStreamBox()
    private(set) var scanType: DataScannerConfiguration = .default
    @ObservationIgnored private var streamTask: Task<Void, Never>?

    var isScanningPossible: Bool {
        DataScanner.scannerAvailable
    }

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

    func startScan(for type: DataScannerConfiguration) {
        scanType = type
        reset()
        showScanner.toggle()
    }

    /// Demonstrates the completion-closure channel.
    func handle(_ outcome: ScanOutcome) {
        print("Callback outcome: \(outcome)")
    }

    func reset() {
        scanning = false
        scanResponse = nil
    }
}
