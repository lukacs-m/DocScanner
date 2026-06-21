//
//  DataScanner.swift
//
//
//  Created by martin on 01/09/2023.
//

import OSLog
import SwiftUI
import VisionKit

/**
 The `DataScanner` is a tool facilitating image to data scanning using the device's camera and handling the scanned information results.
 This tool is based on the [DataScannerViewController](https://developer.apple.com/documentation/visionkit/scanning_data_with_the_camera)
 */
@available(macCatalyst, unavailable)
public struct DataScannerConfiguration {
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    let documentType: DataScanType
    let qualityLevel: DataScannerViewController.QualityLevel
    let recognizesMultipleItems: Bool
    let isHighFrameRateTrackingEnabled: Bool
    let isPinchToZoomEnabled: Bool
    let isGuidanceEnabled: Bool
    let isHighlightingEnabled: Bool

    public init(recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>,
                documentType: DataScanType,
                qualityLevel: DataScannerViewController.QualityLevel = .balanced,
                recognizesMultipleItems: Bool = false,
                isHighFrameRateTrackingEnabled: Bool = true,
                isPinchToZoomEnabled: Bool = false,
                isGuidanceEnabled: Bool = true,
                isHighlightingEnabled: Bool = true) {
        self.recognizedDataTypes = recognizedDataTypes
        self.documentType = documentType
        self.qualityLevel = qualityLevel
        self.recognizesMultipleItems = recognizesMultipleItems
        self.isHighFrameRateTrackingEnabled = isHighFrameRateTrackingEnabled
        self.isPinchToZoomEnabled = isPinchToZoomEnabled
        self.isGuidanceEnabled = isGuidanceEnabled
        self.isHighlightingEnabled = isHighlightingEnabled
    }

    public static var `default`: DataScannerConfiguration {
        DataScannerConfiguration(recognizedDataTypes: [.text(), .barcode()],
                                 documentType: .data)
    }

    public static var `card`: DataScannerConfiguration {
        DataScannerConfiguration(recognizedDataTypes: [.text()],
                                 documentType: .card(ScanInterpreter()),
                                 qualityLevel: .accurate,
                                 recognizesMultipleItems: true,
                                 isGuidanceEnabled: false,
                                 isHighlightingEnabled: false)
    }

    public static var `barcode`: DataScannerConfiguration {
        DataScannerConfiguration(recognizedDataTypes: [.barcode()],
                                 documentType: .barcode,
                                 qualityLevel: .accurate)
    }
}

@available(macCatalyst, unavailable)
@MainActor
public struct DataScanner: UIViewControllerRepresentable {
    @Binding private var startScanning: Bool
    @Binding private var regionOfInterest: CGRect?
    @Binding private var scanResult: (any ScanResult)?
    @Binding private var shouldDismiss: Bool
    private var automaticDismiss: Bool
    private let completionHandler: (ScanOutcome) -> Void
    private let resultStream: ScanResultStreamBox?

    let configuration: DataScannerConfiguration

    public typealias UIViewControllerType = DataScannerViewController

    public static var scannerAvailable: Bool {
        DataScannerViewController.isSupported &&
        DataScannerViewController.isAvailable
    }

    public init(with configuration: DataScannerConfiguration,
                startScanning: Binding<Bool>,
                shouldDismiss: Binding<Bool> = .constant(false),
                automaticDismiss: Bool = true,
                regionOfInterest: Binding<CGRect?> = .constant(nil),
                scanResult: Binding<(any ScanResult)?> = .constant(nil),
                resultStream: ScanResultStreamBox? = nil,
                completion: @escaping (ScanOutcome) -> Void = { _ in }) {
        self.configuration = configuration
        self._startScanning = startScanning
        self._regionOfInterest = regionOfInterest
        self._scanResult = scanResult
        self.completionHandler = completion
        self.resultStream = resultStream
        self._shouldDismiss = shouldDismiss
        self.automaticDismiss = automaticDismiss
    }

    public func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(recognizedDataTypes: configuration.recognizedDataTypes,
                                                       qualityLevel: configuration.qualityLevel,
                                                       recognizesMultipleItems: configuration.recognizesMultipleItems,
                                                       isHighFrameRateTrackingEnabled: configuration.isHighFrameRateTrackingEnabled,
                                                       isPinchToZoomEnabled: configuration.isPinchToZoomEnabled,
                                                       isGuidanceEnabled: configuration.isGuidanceEnabled,
                                                       isHighlightingEnabled: configuration.isHighlightingEnabled)
        viewController.delegate = context.coordinator
        context.coordinator.viewController = viewController
        return viewController
    }

    public func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if shouldDismiss {
            uiViewController.stopScanning()
            uiViewController.dismiss(animated: true)
        }

        if startScanning, !uiViewController.isScanning {
            do {
                try uiViewController.startScanning()
            } catch {
                Logger.docScanner.error("Failed to start scanning: \(error.localizedDescription)")
            }
        } else if !startScanning, uiViewController.isScanning {
            uiViewController.stopScanning()
        }
        addScanningRegionOfInterest(controller: uiViewController)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func addScanningRegionOfInterest(controller: DataScannerViewController) {
        guard controller.isScanning,
              regionOfInterest != controller.regionOfInterest else {
            return
        }
        controller.regionOfInterest = regionOfInterest
    }

    @MainActor
    public final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let dataScannerView: DataScanner
        weak var viewController: DataScannerViewController?

        init(_ dataScannerView: DataScanner) {
            self.dataScannerView = dataScannerView
        }

        /// Handles when a person or your code changes the zoom factor.
        public func dataScannerDidZoom(_ dataScanner: DataScannerViewController) {}

        /// Handles when a person taps an item that the data scanner recognizes.
        public func dataScanner(_ dataScanner: DataScannerViewController,
                                didTapOn item: RecognizedItem) {
            processItem(item: item)
        }

        /// Handles when the data scanner starts recognizing an item.
        public func dataScanner(_ dataScanner: DataScannerViewController,
                                didAdd addedItems: [RecognizedItem],
                                allItems: [RecognizedItem]) {
            switch dataScannerView.configuration.documentType {
            case let .card(interpreter):
                scanCard(items: addedItems, interpreter: interpreter)
            case .data:
                scanData(items: addedItems)
            case .barcode:
                scanBarcode(items: addedItems)
            case let .custom(interpreter):
                scanCustom(items: addedItems, interpreter: interpreter)
            }
        }

        /// Handles when the data scanner becomes unavailable and stops scanning.
        public func dataScanner(_ dataScanner: DataScannerViewController,
                                becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            respond(.failed(error))
            stopScanAndDismiss()
        }

        private func processItem(item: RecognizedItem) {
            switch item {
            case let .text(text):
                respond(.scanned(GenericData(scannedData: [text.transcript])))
                stopScanAndDismiss()
            case let .barcode(codeData):
                respond(.scanned(Barcode(payload: codeData.payloadStringValue ?? "")))
                stopScanAndDismiss()
            @unknown default:
                Logger.docScanner.warning("Unrecognized scanned item type")
            }
        }

        private func scanCard(items: [RecognizedItem], interpreter: any ScanInterpreting) {
            let parsedText = items.filter(\.isText).compactMap(\.value)
            guard !parsedText.isEmpty else {
                return
            }

            Task { [weak self] in
                guard let self else { return }
                let response = await interpreter.interpretCard(from: parsedText, image: nil)
                guard let card = response as? CardDetails,
                      let number = card.number,
                      !number.isEmpty else {
                    return
                }

                var capturedImage: UIImage?
                do {
                    capturedImage = try await self.viewController?.capturePhoto()
                } catch {
                    Logger.docScanner.error("Card photo capture failed: \(error.localizedDescription)")
                }

                self.respond(.scanned(card.updateWithImage(image: capturedImage)))
                self.stopScanAndDismiss()
            }
        }

        private func scanData(items: [RecognizedItem]) {
            let parsedStringData = items.compactMap(\.value)
            guard !parsedStringData.isEmpty else {
                return
            }
            respond(.scanned(GenericData(scannedData: parsedStringData)))
            stopScanAndDismiss()
        }

        private func scanBarcode(items: [RecognizedItem]) {
            let parsedBarcode = items.filter { !$0.isText }.compactMap(\.value)
            guard let payload = parsedBarcode.first else {
                return
            }
            respond(.scanned(Barcode(payload: payload)))
            stopScanAndDismiss()
        }

        private func scanCustom(items: [RecognizedItem], interpreter: any ScanInterpreting) {
            let parsedData = items.compactMap(\.value)
            guard !parsedData.isEmpty else {
                return
            }

            Task { [weak self] in
                let response = await interpreter.interpret(recognizedStrings: parsedData)
                self?.respond(.scanned(response))
                self?.stopScanAndDismiss()
            }
        }

        /// Sends the scan outcome to every delivery channel.
        private func respond(_ outcome: ScanOutcome) {
            dataScannerView.completionHandler(outcome)
            dataScannerView.resultStream?.yield(outcome)
            switch outcome {
            case let .scanned(result):
                dataScannerView.scanResult = result
            case .cancelled, .failed:
                dataScannerView.scanResult = nil
            }
        }

        private func stopScanAndDismiss() {
            guard dataScannerView.automaticDismiss else {
                return
            }
            viewController?.stopScanning()
            viewController?.dismiss(animated: true)
            dataScannerView.shouldDismiss = true
        }
    }
}
