//
//  GenericData.swift
//  DocScannerDemo
//
//  Created by martin on 04/09/2023.
//

import Foundation

public struct GenericData: ScanResult {
    public let scannedData: [String]
    
    public init(scannedData: [String]) {
        self.scannedData = scannedData
    }
}
