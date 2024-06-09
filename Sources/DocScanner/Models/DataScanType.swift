//
//  DataScanType.swift
//  DocScannerDemo
//
//  Created by martin on 04/09/2023.
//

public enum DataScanType: Sendable {
    case data
    case barcode
    case card(any ScanInterpreting)
    case custom(any ScanInterpreting)

  public var scanInterpreter: (any ScanInterpreting)? {
        switch self {
        case let .card(interpreter), let .custom(interpreter):
            return interpreter
        default:
            return nil
        }
    }
}
