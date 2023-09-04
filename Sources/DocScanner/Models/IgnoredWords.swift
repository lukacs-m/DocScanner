//
//  IgnoredWords.swift
//  DocScannerDemo
//
//  Created by martin on 27/08/2023.
//

import Foundation

struct IgnoredWords: Decodable, Sendable {
    let words: [String]
}
