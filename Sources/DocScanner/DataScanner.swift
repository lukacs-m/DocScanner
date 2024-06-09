//
//  DataScanner.swift
//
//
//  Created by martin on 01/09/2023.
//

import Combine
import Foundation
import SwiftUI
import Vision
import VisionKit

/**
 The `DataScanner` is a tool facilitating image to data scanning using the device's camera and handling the scanned information results.
 This tool is based on the new [DataScannerViewController](https://developer.apple.com/documentation/visionkit/scanning_data_with_the_camera)
 */
@available(iOS 16.0, *)
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

@available(iOS 16.0, *)
@available(macCatalyst, unavailable)
@MainActor
public struct DataScanner: UIViewControllerRepresentable {
    @Binding private var startScanning: Bool
    @Binding private var regionOfInterest: CGRect?
    @Binding private var scanResult: (any ScanResult)?
    @Binding private var shouldDismiss: Bool
    private var automaticDismiss: Bool
    private let completionHandler: (Result<(any ScanResult)?, any Error>) -> Void
    private let resultStream: PassthroughSubject<(any ScanResult)?, any Error>?
  
    let configuration: DataScannerConfiguration
    
    public typealias UIViewControllerType = DataScannerViewController
    
    public static var scannerAvailable: Bool {
        DataScannerViewController.isSupported &&
        DataScannerViewController.isAvailable
    }
    
    public init(with configuration: DataScannerConfiguration,
                startScanning: Binding<Bool>,
                shouldDismiss: Binding<Bool> = Binding.constant(false),
                automaticDismiss: Bool = true,
                regionOfInterest: Binding<CGRect?> = Binding.constant(nil),
                scanResult: Binding<(any ScanResult)?> = Binding.constant(nil),
                resultStream: PassthroughSubject<(any ScanResult)?, any Error>? = nil,
                completion: @escaping (Result<(any ScanResult)?, any Error>) -> Void = { _ in }) {
        self.configuration = configuration
        self._startScanning = startScanning
        self._regionOfInterest = regionOfInterest
        self._scanResult = scanResult
        self.completionHandler = completion
        self.resultStream = resultStream
        self._shouldDismiss = shouldDismiss
        self.automaticDismiss = automaticDismiss
    }
    
    public func makeUIViewController(context: UIViewControllerRepresentableContext<DataScanner>) -> DataScannerViewController {
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
    
    public func updateUIViewController(_ uiViewController: DataScannerViewController,
                                       context: UIViewControllerRepresentableContext<DataScanner>) {
        if shouldDismiss {
            uiViewController.stopScanning()
            uiViewController.dismiss(animated: true)
        }

        if startScanning, !uiViewController.isScanning {
            try? uiViewController.startScanning()
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
        DispatchQueue.main.async {
            controller.regionOfInterest = regionOfInterest
        }
    }
    
    @MainActor
    public final class Coordinator: NSObject, DataScannerViewControllerDelegate, Sendable {
        private let dataScannerView: DataScanner
        weak var viewController: DataScannerViewController?
        
        init(_ dataScannerView: DataScanner) {
            self.dataScannerView = dataScannerView
        }

        /// Handles when a person or your code changes the zoom factor.
        ///
        /// The data scanner invokes this method when the
        /// ``DataScannerViewController/zoomFactor`` property changes.
        ///
        /// - Parameter dataScanner: The data scanner whose zoom factor changes.
        public func dataScannerDidZoom(_ dataScanner: DataScannerViewController) {}
        
        /// Handles when a person taps an item that the data scanner recognizes.
        ///
        /// Implement this method to take some action, depending on the type of data
        /// that a person taps.
        ///
        /// - Parameter dataScanner: The data scanner with the zoom factor that changes.
        /// - Parameter item: The item that a person taps.
        public func dataScanner(_ dataScanner: DataScannerViewController,
                                didTapOn item: RecognizedItem) {
            processItem(item: item)
        }
        
        /// Handles when the data scanner starts recognizing an item.
        ///
        /// To identify an item in the `addedItems` and `allItems` parameters, use the
        /// item’s ``RecognizedItem/id-6uksh`` property.
        ///
        /// - Parameter dataScanner: The data scanner that recognizes the item.
        /// - Parameter addedItems: The items that the data scanner starts tracking.
        /// - Parameter allItems: The current items that the data scanner tracks. Text items
        /// appear in the reading order of the language and region.
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
        ///
        /// - Parameter dataScanner: The data scanner that’s not available.
        /// - Parameter error: Describes an error if it occurs.
        public func dataScanner(_ dataScanner: DataScannerViewController,
                                becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            dataScannerView.completionHandler(.failure(error))
            dataScannerView.scanResult = nil
            dataScannerView.resultStream?.send(nil)
            stopScanAndDismiss()
        }
        
       private func processItem(item: RecognizedItem) {
            switch item {
            case .text(let text):
                let data = GenericData(scannedData: [text.transcript])
                respond(with: data)
                stopScanAndDismiss()
            case .barcode(let codeData):
                // Open the URL in the browser.
                let barcode = Barcode(payload: codeData.payloadStringValue ?? "")
                respond(with: barcode)
                stopScanAndDismiss()
            @unknown default:
                print("Unknown Items")
            }
        }
   
        private func scanCard(items: [RecognizedItem], interpreter: any ScanInterpreting) {
            let parsedText = items.filter { $0.isText }.compactMap(\.value)
            guard !parsedText.isEmpty,
                  let interpreter = interpreter as? (any CardInterpreting) else {
                return
            }
            
            Task { [weak self] in
                let response = await interpreter.parseCardResults(for: parsedText, and: nil)
                guard let card = response as? CardDetails,
                      let number = card.number,
                      !number.isEmpty else {
                    return
                }
                let image = try? await self?.viewController?.capturePhoto()
                
                self?.respond(with: card.updateWithImage(image: image))
                self?.stopScanAndDismiss()
            }
        }
        
        private func scanData(items: [RecognizedItem]) {
            let parsedStringData = items.compactMap(\.value)
            guard !parsedStringData.isEmpty else {
                return
            }
            let data = GenericData(scannedData: parsedStringData)
            respond(with: data)
        }
        
        private func scanBarcode(items: [RecognizedItem]) {
            let parsedBarcode = items.filter { !$0.isText }.compactMap(\.value)
            
            guard let payload = parsedBarcode.first else {
                return
            }
            let barcode = Barcode(payload: payload)
            respond(with: barcode)
            stopScanAndDismiss()
        }

        private func scanCustom(items: [RecognizedItem], interpreter: any ScanInterpreting) {
            let parsedData = items.compactMap(\.value)
            guard !parsedData.isEmpty else {
                return
            }

            Task { [weak self] in
                let response = await interpreter.parseAndInterpret(data: parsedData)

                self?.respond(with: response)
            }
        }

        /**
         Sends the interpreted scan response to the provided result stream and completion handler.
         
         - Parameter result: The interpreted scan response.
         */
        private func respond(with result: any ScanResult) {
            dataScannerView.completionHandler(.success(result))
            dataScannerView.scanResult = result
            dataScannerView.resultStream?.send(result)
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
