# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-21

First major release: modernized for **Swift 6** and **iOS 18** with a redesigned,
type-safe, race-safe API. This release contains breaking changes — see _Migration_.

### Requirements

- iOS 18+ (previously iOS 15+)
- Swift 6 language mode

### Migration (breaking changes)

- **Platforms:** minimum deployment target is now iOS 18, and **macOS is no longer
  supported** (the underlying VisionKit scanners are unavailable on macOS AppKit).
- **Interpreter protocol redesign:**
  - `ScanInterpreting` now requires `Sendable` instead of `Actor`, so an interpreter
    can be a value type, a `@MainActor` class, or an actor.
  - Removed `parseAndInterpret(data: Any)` and the `DocScanInterpreting` /
    `CardInterpreting` sub-protocols. They are replaced by three statically-typed
    methods — `interpret(scan:)`, `interpretCard(from:image:)`,
    `interpret(recognizedStrings:)` — each with a default implementation, so a custom
    interpreter only implements what it needs. The runtime downcasts at the call sites
    are gone.
  - `ScanInterpreter` is now a `struct` (was an `actor`); construct and inject it the
    same way as before.
- **Unified result delivery via `ScanOutcome`:**
  - Completion closures are now `(ScanOutcome) -> Void` (was
    `(Result<(any ScanResult)?, any Error>) -> Void`). User cancellation is the
    first-class case `.cancelled` instead of `.success(nil)`.
  - The Combine `PassthroughSubject` `resultStream` parameter is replaced by a
    `ScanResultStreamBox` that vends an `AsyncStream<ScanOutcome>`.
  - `DocScanner` and `DataScanner` now use the same outcome type (previously their
    result/nullability types differed).
- **No-interpreter behavior:** `VNDocumentCameraScan` no longer conforms to
  `ScanResult`. When no interpreter is supplied, `DocScanner` falls back to the
  built-in `ScanInterpreter(type: .document)` instead of returning the raw scan.
- **Typed errors:** document interpretation uses typed throws
  (`throws(ScanInterpreterError)`); Vision failures are surfaced instead of being
  swallowed into an empty result.

### Added

- `ScanOutcome`, `ScanInterpreterError`, `ScanResultStreamBox`, and an `@Observable`
  `ScannerModel` convenience for consuming results via `AsyncStream`.
- Native async Vision text recognition (`RecognizeTextRequest`) executed off the main
  actor with `@concurrent`.
- A Swift Testing unit-test suite covering card-number/type/industry classification and
  expiry, CVV, and name parsing.
- `os.Logger`-based logging.

### Changed

- `RestrictedScanningArea` now uses `onGeometryChange` and `foregroundStyle`.
- The example app was migrated to the Observation framework
  (`@Observable` / `@State` / `@Bindable`) and the new `AsyncStream` result channel.
- CI builds and tests on an iOS simulator via `xcodebuild` and runs SwiftLint.
- README updated for the new API, requirements, and result channels.

### Fixed

- Text recognition silently ran with default settings: the configured request
  (`.accurate` level, language correction, custom words) was overwritten before use.
  Recognition now applies the intended configuration.
- The cardholder-name filter never matched card-brand words, because card-type names
  were compared mixed-case against lowercased text. The avoid-list is now lowercased
  (and decoded once — see below).
- `ignoredWords.json` was reloaded and re-decoded on every recognized line; it is now
  decoded a single time.
- `DataScanner` `.data` and `.custom` modes ignored the `automaticDismiss` flag and
  never auto-dismissed; all scan modes now honor it consistently.

### Removed

- macOS platform support.
- Combine from the public API (the `PassthroughSubject` result stream).
- Dead/unused declarations.

[1.0.0]: https://github.com/lukacs-m/DocScanner/compare/0.2.6...1.0.0
