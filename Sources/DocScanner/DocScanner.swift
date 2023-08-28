import Combine
import SwiftUI
import Vision
import VisionKit

public struct DocScanner: UIViewControllerRepresentable {
    private let interpreter: ScanInterpreting?
    private let completionHandler: (Result<ScanResponse?, Error>) -> Void
    private let resultStream: PassthroughSubject<ScanResponse?, Error>?
    @Binding private var scanResult: ScanResponse?
    
    public typealias UIViewControllerType = VNDocumentCameraViewController
    
    public init(with interpreter: ScanInterpreting? = nil,
                scanResult: Binding<ScanResponse?> = Binding.constant(nil),
                resultStream: PassthroughSubject<ScanResponse?, Error>? = nil,
                completion: @escaping (Result<ScanResponse?, Error>) -> Void = { _ in }) {
        self.completionHandler = completion
        self._scanResult = scanResult
        self.resultStream = resultStream
        self.interpreter = interpreter
    }
    
    public func makeUIViewController(context: UIViewControllerRepresentableContext<DocScanner>) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController,
                                       context: UIViewControllerRepresentableContext<DocScanner>) {
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(with: interpreter,
                    scanResult: $scanResult,
                    resultStream: resultStream,
                    completionHandler: completionHandler)
    }
    
    public final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        @Binding var scanResult: ScanResponse?

        private let interpreter: ScanInterpreting?
        private let completionHandler: (Result<ScanResponse?, Error>) -> Void
        private let resultStream: PassthroughSubject<ScanResponse?, Error>?
        
        init(with interpreter: ScanInterpreting? = nil,
             scanResult: Binding<ScanResponse?> = Binding.constant(nil),
             resultStream: PassthroughSubject<ScanResponse?, Error>? = nil,
             completionHandler: @escaping (Result<ScanResponse?, Error>) -> Void = { _ in }) {
            self.completionHandler = completionHandler
            self._scanResult = scanResult
            self.resultStream = resultStream
            self.interpreter = interpreter
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                                 didFinishWith scan: VNDocumentCameraScan) {
            print("Document camera view controller did finish with ", scan)
            guard let interpreter else {
                respond(with: scan)
                return
            }
            Task { [weak self] in
                let response = await interpreter.parseAndInterpret(scans: scan)
                self?.respond(with: response)
                await controller.dismiss(animated: true)
            }
        }
        
        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            Task { @MainActor [weak self] in
                self?.completionHandler(.success(nil))
                self?.scanResult = nil
                self?.resultStream?.send(nil)
                controller.dismiss(animated: true)
            }
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                                 didFailWithError error: Error) {
            Task { @MainActor [weak self] in
                self?.completionHandler(.failure(error))
                self?.scanResult = nil
                self?.resultStream?.send(completion: .failure(error))
                controller.dismiss(animated: true)
            }
        }
        
        private func respond(with result: ScanResponse) {
            Task { @MainActor [weak self] in
                self?.completionHandler(.success(result))
                self?.scanResult = result
                self?.resultStream?.send(result)
            }
        }
    }
}
