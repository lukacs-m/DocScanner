//
//  ScanResultStreamBox.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

/// A stable home for a scanner's `AsyncStream` of outcomes.
///
/// A `UIViewControllerRepresentable` struct is recreated on every SwiftUI update, so an
/// `AsyncStream.Continuation` must **not** live on the struct — it would be discarded
/// and recreated, dropping events. Instead, the caller creates one box, holds it for the
/// scanner's lifetime, and passes it in; the scanner's coordinator yields outcomes into it.
///
/// This is the modern replacement for passing a Combine `PassthroughSubject`.
public final class ScanResultStreamBox: Sendable {
    /// The stream of scan outcomes. Iterate it with `for await`.
    ///
    /// `AsyncStream` is single-consumer — iterate it in exactly one place
    /// (or let ``ScannerModel`` own it for you).
    public let stream: AsyncStream<ScanOutcome>
    private let continuation: AsyncStream<ScanOutcome>.Continuation

    public init() {
        let (stream, continuation) = AsyncStream<ScanOutcome>.makeStream()
        self.stream = stream
        self.continuation = continuation
    }

    /// Forwards an outcome to the stream.
    public func yield(_ outcome: ScanOutcome) {
        continuation.yield(outcome)
    }

    /// Terminates the stream so consumer loops exit.
    public func finish() {
        continuation.finish()
    }

    deinit {
        continuation.finish()
    }
}
