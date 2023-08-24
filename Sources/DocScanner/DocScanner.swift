import Combine
import Vision
import VisionKit
import SwiftUI

//public protocol ScanInterpreting: Actor {
//     func parseAndInterprete(scans:VNDocumentCameraScan) async -> ScanResponse
//}

//protocol ScanInterpreting {
//    func parseAndInterprete() -> ScanResponse
//}



//struct CardDetails: ScanResponse {
//    let numberWithDelimiters: String?
//    let name: String?
//    let expiryDate: String?
//}
//

//
//func validateImage(image: UIImage?, completion: @escaping (CardDetails?) -> Void) {
//    guard let cgImage = image?.cgImage else { return completion(nil) }
//
//    var recognizedText = [String]()
//
//    var textRecognitionRequest = VNRecognizeTextRequest()
//    textRecognitionRequest.recognitionLevel = .accurate
//    textRecognitionRequest.usesLanguageCorrection = false
//    textRecognitionRequest.customWords = CardType.allCases.map { $0.rawValue } + ["Expiry Date"]
//    textRecognitionRequest = VNRecognizeTextRequest() { (request, error) in
//        guard let results = request.results,
//              !results.isEmpty,
//              let requestResults = request.results as? [VNRecognizedTextObservation]
//        else { return completion(nil) }
//        recognizedText = requestResults.compactMap { observation in
//            return observation.topCandidates(1).first?.string
//        }
//    }
//
//    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//    do {
//        try handler.perform([textRecognitionRequest])
//        completion(parseResults(for: recognizedText))
//    } catch {
//        print(error)
//    }
//}
//
//
//

public struct DocScanner: UIViewControllerRepresentable {
    private let interpreter: ScanInterpreting?
    private let completionHandler: (Result<ScanResponse?, Error>) -> Void
    public let resultStream: PassthroughSubject<ScanResponse?, Error> = .init()
    @Binding private var scanResult: ScanResponse?

    public typealias UIViewControllerType = VNDocumentCameraViewController

   public init(with interpreter: ScanInterpreting? = nil,
         scanResult: Binding<ScanResponse?> = Binding.constant(nil),
         completion: @escaping (Result<ScanResponse?, Error>) -> Void = { _ in }) {
        self.completionHandler = completion
        self._scanResult = scanResult
        self.interpreter = interpreter
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<DocScanner>) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: UIViewControllerRepresentableContext<DocScanner>) {
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(with: interpreter,
                    scanResult: $scanResult,
                    resultStream: resultStream,
                    completionHandler: completionHandler)
    }

    final public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let interpreter: ScanInterpreting?
        private let completionHandler: (Result<ScanResponse?, Error>) -> Void
        private let resultStream: PassthroughSubject<ScanResponse?, Error>
        @Binding var scanResult: ScanResponse?

        init(with interpreter: ScanInterpreting? = nil,
            scanResult: Binding<ScanResponse?> = Binding.constant(nil),
             resultStream: PassthroughSubject<ScanResponse?, Error>,
            completionHandler: @escaping (Result<ScanResponse?, Error>) -> Void) {
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
                let response = await interpreter.parseAndInterprete(scans: scan)
                self?.respond(with: response)
            }
        }

        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            completionHandler(.success(nil))
            scanResult = nil
            resultStream.send(nil)
        }

        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document camera view controller did finish with error ", error)
            completionHandler(.failure(error))
            scanResult = nil
            resultStream.send(completion: .failure(error))
        }

        private func respond(with result: ScanResponse) {
            completionHandler(.success(result))
            scanResult = result
            resultStream.send(result)
        }
    }

}
