//
//  DocScannerDemoViewModel.swift
//  
//
//  Created by martin on 01/09/2023.
//

import Foundation
import DocScanner
import Combine

@MainActor
final class DocScannerDemoViewModel: ObservableObject {
    @Published var scanResponse: ScanResult?
    @Published var showScanner = false
    let scanResponsePublisher: PassthroughSubject<Result<ScanResult?, Error>, Never> = .init()
    private var scanType: DocScanType = .document
    private var cancellable = Set<AnyCancellable>()
    private var task: Task<Void, Never>?
    
    init() {
       scanResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { scanResult in
                print("Publisher scan results: \(String(describing: scanResult))")
            }.store(in: &cancellable)
        
        $scanResponse
            .receive(on: DispatchQueue.main)
            .sink { scanResult in
                print("@Published scan results: \(String(describing: scanResult))")
            }.store(in: &cancellable)
        
        asyncSequenceResults()
    }
    
    deinit {
        print("woot deinit DocScannerDemoViewModel")
        task?.cancel()
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
    
    func asyncSequenceResults() {
        task?.cancel()

        task = Task { [scanResponsePublisher] in
            for await scanResult in scanResponsePublisher.values {
                print("asyncSequenceResults: \(String(describing: scanResult))")
                if Task.isCancelled {
                    print("asyncSequenceResults cancelled")
                    
                }
            }
        }
    }
}
