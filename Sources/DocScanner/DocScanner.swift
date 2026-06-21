import SwiftUI
import VisionKit

/**
 The `DocScanner` is a tool facilitating document scanning using the device's camera and handling the scanned document results.

 Results are delivered through three optional channels: a completion closure, a SwiftUI
 `@Binding`, and an `AsyncStream` (via ``ScanResultStreamBox``). Use any subset.
 */
public struct DocScanner: UIViewControllerRepresentable {
    private let interpreter: (any ScanInterpreting)?
    private let completionHandler: (ScanOutcome) -> Void
    private let resultStream: ScanResultStreamBox?
    @Binding private var scanResult: (any ScanResult)?
    @Binding private var shouldDismiss: Bool

    public typealias UIViewControllerType = VNDocumentCameraViewController

    @MainActor
    public static var isSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }

    /**
     Initializes a `DocScanner` view.

     - Parameters:
        - interpreter: An optional `ScanInterpreting` object for interpreting scan results. When `nil`, a default `ScanInterpreter(type: .document)` is used.
        - shouldDismiss: A binding toggled when the scanner finishes, fails, or is cancelled.
        - scanResult: A binding to the scan result.
        - resultStream: An optional stream box for observing scan outcomes as an `AsyncStream`.
        - completion: A closure handling the scan outcome.
    */
    public init(with interpreter: (any ScanInterpreting)? = nil,
                shouldDismiss: Binding<Bool> = .constant(false),
                scanResult: Binding<(any ScanResult)?> = .constant(nil),
                resultStream: ScanResultStreamBox? = nil,
                completion: @escaping (ScanOutcome) -> Void = { _ in }) {
        self.completionHandler = completion
        self._scanResult = scanResult
        self.resultStream = resultStream
        self.interpreter = interpreter
        self._shouldDismiss = shouldDismiss
    }

    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self, and: interpreter)
    }

    @MainActor
    public final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let docScanner: DocScanner
        private let interpreter: any ScanInterpreting

        init(_ docScanner: DocScanner, and interpreter: (any ScanInterpreting)? = nil) {
            self.docScanner = docScanner
            self.interpreter = interpreter ?? ScanInterpreter(type: .document)
        }

        /// Handles the completion of scanning with scanned document pages.
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                                 didFinishWith scan: VNDocumentCameraScan) {
            Task {
                do {
                    let result = try await interpreter.interpret(scan: scan)
                    respond(with: .scanned(result), controller: controller)
                } catch {
                    respond(with: .failed(error), controller: controller)
                }
            }
        }

        /// Handles the cancellation of scanning.
        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            respond(with: .cancelled, controller: controller)
        }

        /// Handles errors that might occur during scanning.
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                                 didFailWithError error: any Error) {
            respond(with: .failed(error), controller: controller)
        }

        /// Sends the scan outcome to every delivery channel and dismisses the scanner.
        private func respond(with outcome: ScanOutcome, controller: VNDocumentCameraViewController) {
            docScanner.completionHandler(outcome)
            docScanner.resultStream?.yield(outcome)
            switch outcome {
            case let .scanned(result):
                docScanner.scanResult = result
            case .cancelled, .failed:
                docScanner.scanResult = nil
            }
            docScanner.shouldDismiss.toggle()
            controller.dismiss(animated: true)
        }
    }
}
