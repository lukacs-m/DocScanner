//
//  ContentViewModel.swift
//  DocScannerDemo
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation
import DocScanner
import Combine

final class ContentViewModel: ObservableObject {
    @Published var scanResponse: ScanResponse?
    private var scanType: DocScanType = .document
    @Published var showScanner = false    
    let scanResponsePublisher: PassthroughSubject<ScanResponse?, Error> = .init()
    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = scanResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { scanResult in
                print("Publisher scan results: \(String(describing: scanResult))")
            }
    }

    var interpretor: ScanInterpreter {
        ScanInterpreter(type: scanType)
    }
    
    func startScan(for type: DocScanType = .document) {
        scanType = type
        showScanner.toggle()
    }
    
    func callbackResults(results: Result<ScanResponse?, Error>) {
        print("Callback scan results: \(results)")
    }
}
