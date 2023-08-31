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
    @Published var scanResponse: ScanResult?
    private var scanType: DocScanType = .document
    @Published var showScanner = false    
    let scanResponsePublisher: PassthroughSubject<ScanResult?, Error> = .init()
    private var cancellable = Set<AnyCancellable>()
    
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

    var interpretor: ScanInterpreter {
        ScanInterpreter(type: scanType)
    }
    
    func startScan(for type: DocScanType = .document) {
        scanType = type
        showScanner.toggle()
    }
    
    func callbackResults(results: Result<ScanResult?, Error>) {
        print("Callback scan results: \(results)")
    }
}
