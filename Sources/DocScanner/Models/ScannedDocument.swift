//
//  ScannedDocument.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation

public struct ScannedDocument: ScanResult {
    public let title: String
    public let scannedPages: [Page]
    
    public init(title: String, scannedPages: [Page]) {
        self.scannedPages = scannedPages
        self.title = title
    }
}
