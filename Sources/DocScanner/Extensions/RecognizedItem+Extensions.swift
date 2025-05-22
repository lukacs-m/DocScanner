//
//  RecognizedItem+Extensions.swift
//  DocScannerDemo
//
//  Created by martin on 04/09/2023.
//

import Foundation
import VisionKit

@available(iOS 16.0, *)
@available(macCatalyst, unavailable)
extension RecognizedItem: @retroactive Equatable {
    public static func == (lhs: RecognizedItem, rhs: RecognizedItem) -> Bool {
        lhs.id == rhs.id
    }
    
    var isText: Bool {
        switch self {
        case .text:
            return true
        default: return false
        }
    }
    
    var value: String? {
        switch self {
        case let .text(value):
            return value.transcript
        case let .barcode(code):
            return code.payloadStringValue
        @unknown default:
            return nil
        }
    }
}
