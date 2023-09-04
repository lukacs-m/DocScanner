//
//  Barcode.swift
//  DocScannerDemo
//
//  Created by martin on 04/09/2023.
//

import Foundation

public struct Barcode: ScanResult {
    public let payload: String
    
    public init(payload: String) {
        self.payload = payload
    }
}
