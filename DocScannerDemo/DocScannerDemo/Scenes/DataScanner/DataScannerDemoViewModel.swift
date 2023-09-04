//
//  DataScannerDemoViewModel.swift
//  DocScannerDemo
//
//  Created by martin on 04/09/2023.
//

import Foundation
import DocScanner
import Combine

final class DataScannerDemoViewModel: ObservableObject {
    @Published var scanResponse: ScanResult?
    @Published var showScanner = false
    @Published var applyRegionOfInterest = false
    
    let scanResponsePublisher: PassthroughSubject<ScanResult?, Error> = .init()
    private(set) var scanType: DataScannerConfiguration = .default
    private var cancellable = Set<AnyCancellable>()
    
    @MainActor
    var isScanningPossible: Bool {
        DataScanner.scannerAvailable
    }
    
    init() {
       scanResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { scanResult in
                print("Publisher scan results: \(String(describing: scanResult))")
            }.store(in: &cancellable)
        
        $scanResponse
            .receive(on: DispatchQueue.main)
            .sink { scanResult in
                print("@Published scan results: \(String(describing: scanResult))")
            }.store(in: &cancellable)
    }
    
    func startScan(for type: DataScannerConfiguration) {
        scanType = type
        showScanner.toggle()
    }
    
    func callbackResults(results: Result<ScanResult?, Error>) {
        print("Callback scan results: \(results)")
    }
}
