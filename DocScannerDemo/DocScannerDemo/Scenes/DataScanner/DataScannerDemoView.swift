//
//  DataScannerDemoView.swift
//
//
//  Created by martin on 01/09/2023.
//

import DocScanner
import SwiftUI

struct DataScannerDemoView: View {
    @StateObject private var viewModel = DataScannerDemoViewModel()
    @State private var showDeviceNotCapacityAlert = false
    @State private var show = false

    var body: some View {
        VStack {
            scannedContent
                .padding()
            
            HStack {
                Spacer()
                Toggle("Apply scanning field restriction", isOn: $viewModel.applyRegionOfInterest)
                Spacer()
            }
            .frame(width: 400)

            HStack {
                Spacer()
                Toggle("Automatically dismiss scanner when scan finished", isOn: $viewModel.automaticDismiss)
                Spacer()
            }
            .frame(width: 400)

            scanActionButtons
        }
        .fullScreenCover(isPresented: $viewModel.showScanner) {
            ZStack(alignment: .bottom) {
                DataScanner(with: viewModel.scanType,
                            startScanning: $viewModel.scanning,
                            shouldDismiss:  Binding(
                                get: { !viewModel.showScanner},
                                set: { viewModel.showScanner = !$0 }
                            ),
                            automaticDismiss: viewModel.automaticDismiss,
                            regionOfInterest: $viewModel.regionOfInterest,
                            scanResult: $viewModel.scanResponse,
                            resultStream: viewModel.scanResponsePublisher) { results in
                    viewModel.callbackResults(results: results)
                }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(regionOfInterestOverlay)
                VStack {
                    VStack {
                        Text("Content of scan:")
                        if !viewModel.automaticDismiss {
                            if viewModel.scanResponse == nil {
                                emptyRow
                            } else if let cardDetails = viewModel.scanResponse as? CardDetails {
                                Text(cardDetails.name ?? "")
                            } else if let barcode = viewModel.scanResponse as? Barcode {
                                Text(barcode.payload)
                            } else if let data = viewModel.scanResponse as? GenericData {
                                Text(data.scannedData.first ?? "")
                            }
                        }
                    }.padding()
                        .frame(height: 100)
                        .background(.gray.opacity(0.5))

                    VStack{

                        Button {viewModel.scanning.toggle()} label: {
                            Text( viewModel.scanning ? "Stop scanning" :  "Start Scanning")
                        }
                        .padding()

                        Button {viewModel.showScanner.toggle()} label: {
                            Text( "Dismiss")
                        }
                        .padding()
                    } .background(.gray.opacity(0.5))
                }

                .offset(y: -25)
            }
        }
        .alert("Scanner Unavailable", isPresented: $showDeviceNotCapacityAlert, actions: {})
        .onChange(of: viewModel.applyRegionOfInterest) { value in
            if !value {
                viewModel.regionOfInterest = nil
            }
        }
    }
    
    @ViewBuilder
    var regionOfInterestOverlay: some View {
        if viewModel.applyRegionOfInterest {
            RestrictedScanningArea(regionOfInterest: $viewModel.regionOfInterest)
        } else {
           EmptyView()
        }
    }
}

private extension DataScannerDemoView {
    @ViewBuilder
    var scannedContent: some View {
        if viewModel.scanResponse == nil {
            emptyRow
        } else if let cardDetails = viewModel.scanResponse as? CardDetails {
            cardRow(for: cardDetails)
        } else if let barcode = viewModel.scanResponse as? Barcode {
            barcodeRow(for: barcode)
        } else if let data = viewModel.scanResponse as? GenericData {
            genericDataRow(for: data)
        }
    }
}

private extension DataScannerDemoView {
    func barcodeRow(for barcode: Barcode) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Barcode or QR code payload:")
                .font(.title)
            Text(barcode.payload)
            Spacer()
        }
    }
}

private extension DataScannerDemoView {
    func genericDataRow(for data: GenericData) -> some View {
        ScrollView {
            VStack {
                Spacer()
                Text("Data scanned payload:")
                    .font(.title)
                ForEach(data.scannedData, id: \.self) { payload in
                    Text(payload)
                }
                Spacer()
                
            }
        }
    }
}

private extension DataScannerDemoView {
    var scanActionButtons: some View {
        HStack {
            Button {
                if viewModel.isScanningPossible {
                    viewModel.startScan(for: .default)
                    
                } else {
                    showDeviceNotCapacityAlert = true
                }
            } label: {
                Text("Scan Data")
            }
            .padding()
            
            Divider()
                .frame(height: 15)
            
            Button {
                if viewModel.isScanningPossible {
                    viewModel.startScan(for: .card)
                } else {
                    showDeviceNotCapacityAlert = true
                }
            } label: {
                Text("Scan Card")
            }
            .padding()
            
            Divider()
                .frame(height: 15)
            
            Button {
                if viewModel.isScanningPossible {
                    viewModel.startScan(for: .barcode)
                } else {
                    showDeviceNotCapacityAlert = true
                }
            } label: {
                Text("Scan barcode")
            }
            .padding()
        }
        .foregroundColor(.black)
        .font(.title3.weight(.semibold))
        .background(.white.opacity(0.5))
        .cornerRadius(10)
        .padding()
    }
}
