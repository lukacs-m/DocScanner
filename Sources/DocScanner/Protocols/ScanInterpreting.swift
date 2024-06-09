//
//  ScanInterpreting.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation
import VisionKit

public protocol ScanInterpreting: Actor {
    func parseAndInterpret(data: Any) async -> any ScanResult
}

public protocol DocScanInterpreting: ScanInterpreting {
    func parseAndInterpret(scans: VNDocumentCameraScan) async -> any ScanResult
}

public protocol CardInterpreting: ScanInterpreting {
    func parseCardResults(for recognizedText: [String], and image: UIImage?) -> any ScanResult
}
