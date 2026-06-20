# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`DocScanner` is a zero-dependency Swift Package providing SwiftUI wrappers around Apple's VisionKit/Vision scanning APIs, plus text interpretation for documents and credit cards. Platforms: iOS 15+, macOS 13+. Builds in Swift 6 language mode (`swift-tools-version: 6.3.1`).

## Commands

```bash
swift build                              # Build the library
swift test                               # Run all tests
swift test --filter DocScannerTests/testExample   # Run a single test
swiftlint                                # Lint (config: .swiftlint.yml, only lints Sources/)
swiftlint analyze --compiler-log-path <log>       # Analyzer-only rules (explicit_self, unused_declaration, unused_import)
```

CI (`.github/workflows/swift.yml`) runs `swift build -v` and `swift test -v` on `macos-latest` for pushes/PRs to `main`.

The example app under `DocScannerDemo/` is a separate Xcode project (`DocScannerDemo.xcodeproj`) that consumes the package locally — build it with `xcodebuild` or Xcode, not SPM.

## Architecture

### Two scanner entry points (both `UIViewControllerRepresentable`)

- **`DocScanner`** (`Sources/DocScanner/DocScanner.swift`) — wraps `VNDocumentCameraViewController` for still-image document/card capture. iOS 15+.
- **`DataScanner`** (`Sources/DocScanner/DataScanner.swift`) — wraps `DataScannerViewController` for live camera data scanning (text, barcodes, cards). iOS 16+, `@available(macCatalyst, unavailable)`. Driven by `DataScannerConfiguration` with presets `.default`, `.card`, `.barcode`.

Each scanner's `Coordinator` (the UIKit delegate) is where results are produced and dispatched.

### Triple result delivery

Both scanners emit every result through **three optional channels at once**, all defaulted so callers opt in to any subset:
1. completion closure — `(Result<(any ScanResult)?, any Error>) -> Void`
2. Combine `PassthroughSubject`
3. SwiftUI `@Binding` (`scanResult`)

There's also a `shouldDismiss` binding to drive dismissal from the parent view.

### Interpreter protocol hierarchy

Interpreters are **actors** (`Sources/DocScanner/Protocols/ScanInterpreting.swift`):
- `ScanInterpreting: Actor` — base, `parseAndInterpret(data: Any)`
- `DocScanInterpreting` — adds `parseAndInterpret(scans: VNDocumentCameraScan)`
- `CardInterpreting` — adds `parseCardResults(for:and:)`

`ScanInterpreter` (`Sources/DocScanner/ScanInterpreter.swift`) is an `actor` conforming to all three, configured by `DocScanType` (`.document` / `.card`). Callers can supply a custom interpreter instead.

**Runtime-cast gotcha:** scanners check conformance to the *specific* sub-protocol at runtime. `DocScanner` does `interpreter as? (any DocScanInterpreting)` — if that fails, it returns the raw `VNDocumentCameraScan` uninterpreted. `DataScanner` card mode does `interpreter as? (any CardInterpreting)`. A custom interpreter that only conforms to the base `ScanInterpreting` will be silently bypassed in these paths.

### Result types

`ScanResult: Sendable` (`Sources/DocScanner/Protocols/ScanResult.swift`) is the marker protocol returned as an existential (`any ScanResult`) everywhere. Implementations: `ScannedDocument` (pages), `CardDetails`, `GenericData` (raw text), `Barcode`. `DataScanType` (`.data`/`.barcode`/`.card`/`.custom`) selects which one the `DataScanner` coordinator builds.

### Card-parsing logic lives in extensions, not the interpreter

`ScanInterpreter` only orchestrates; the actual heuristics are in:
- `Extensions/Array+Extensions.swift` — `parseCardNumber` (digit-prefix + length rules for the card number)
- `Extensions/String+Extensions.swift` — `parseExpiryDate`, `parseCVV`, `parseName`. Name detection uses `NaturalLanguage` (`NLTagger`) to *reject* org/place names, plus a `Regex`/`NSRegularExpression` shape check and a filter list loaded from the `ignoredWords.json` resource (`Bundle.module`).

`CardType` and `CardIndustry` (in `Models/CardDetails.swift`) are derived purely from the card number's leading digits and length. Text recognition uses `VNRecognizeTextRequest` at `.accurate`; for cards, language correction is off and `customWords` are seeded from card-type names.

## Concurrency

This is a strict-concurrency (Swift 6) codebase — interpreter protocols require `Actor` conformance, result types are `Sendable`, and coordinators are annotated (`@MainActor` / `@unchecked Sendable` on `DocScanner.Coordinator`, `@MainActor` + `Sendable` on `DataScanner.Coordinator`). Preserve these annotations and the `Sendable` conformances when modifying types that cross the scanner/interpreter boundary.

## Platform conditionals

`CardDetails` and `Page` are wrapped in `#if canImport(UIKit)` because they hold `UIImage`. Anything touching these, or `DataScanner` (iOS 16+), must respect the availability/platform guards.

## Linting notes

`force_unwrapping` is opted in — avoid `!`. A custom rule **`drop_first_one`** forbids `.dropFirst(1)`. Imports must be sorted (`sorted_imports`). See `.swiftlint.yml` for the full opted-in rule set and length limits.
