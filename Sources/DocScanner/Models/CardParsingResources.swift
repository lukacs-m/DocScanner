//
//  CardParsingResources.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation

/// Static, decode-once resources used by card text parsing.
///
/// Previously `ignoredWords.json` was reloaded and re-decoded on *every*
/// `String.parseName` call — and `parseName` runs per recognized text line —
/// causing repeated bundle I/O and JSON decoding for immutable data. These
/// `static let`s are initialized lazily exactly once and are thread-safe.
enum CardParsingResources {
    /// Words decoded once from the bundled `ignoredWords.json`.
    static let ignoredWords: [String] = {
        let decoded: IgnoredWords? = String.loadJson(filename: "ignoredWords")
        return decoded?.words ?? []
    }()

    /// The lowercased avoid-list used by name parsing.
    ///
    /// Card-type names are stored mixed-case (e.g. "MasterCard"), but candidate
    /// text is compared in lowercase — so they must be lowercased here to match.
    static let wordsToAvoid: [String] = (CardType.names + ignoredWords).map { $0.lowercased() }
}
