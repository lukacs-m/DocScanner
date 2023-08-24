//
//  ContentViewModel.swift
//  DocScannerDemo
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation
import DocScanner

final class ContentViewModel: ObservableObject {
    @Published var scanResponse: ScanResponse?
    @Published var scanType: DocScanType = .document
    @Published var showScanner = false

    init() {}

    var interpretor: ScanInterpretor {
        ScanInterpretor(type: scanType)
    }
}
