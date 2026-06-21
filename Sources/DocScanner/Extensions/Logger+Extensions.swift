//
//  Logger+Extensions.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import OSLog

extension Logger {
    /// Shared logger for the DocScanner library.
    static let docScanner = Logger(subsystem: "DocScanner", category: "DocScanner")
}
