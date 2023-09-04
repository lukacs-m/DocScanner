//
//  DocScannerDemoView.swift
//  
//
//  Created by martin on 01/09/2023.
//

import DocScanner
import SwiftUI

struct DocScannerDemoView: View {
    @StateObject private var viewModel = DocScannerDemoViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            scannedContent
            scanActionButtons
        }
        .sheet(isPresented: $viewModel.showScanner) {
            DocScanner(with: viewModel.interpretor,
                       scanResult: $viewModel.scanResponse,
                       resultStream: viewModel.scanResponsePublisher) { results in
                viewModel.callbackResults(results: results)
            }.edgesIgnoringSafeArea(.all)
        }
    }
}

private extension DocScannerDemoView {
    @ViewBuilder
    var scannedContent: some View {
            if viewModel.scanResponse == nil {
                emptyRow
            } else if let cardDetails = viewModel.scanResponse as? CardDetails {
                cardRow(for: cardDetails)
            } else if let scannedDocument = viewModel.scanResponse as? ScannedDocument {
                ScrollView {
                    VStack {
                        ForEach(scannedDocument.scannedPages) { page in
                            pageRow(for: page)
                            if page != scannedDocument.scannedPages.last {
                                Divider()
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
    }
}

private extension DocScannerDemoView {
    func pageRow(for page: Page) -> some View {
        VStack {
            Text("Page number \(page.pageNumber)")
                .font(.title)
            Image(uiImage: page.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 300)
                .padding()
            
            Section("Content of scanned document") {
                VStack(alignment: .leading) {
                    ForEach(page.text, id: \.self) { line in
                        Text(line)
                    }
                }
            }
        }
    }
}

private extension DocScannerDemoView {
    var scanActionButtons: some View {
        HStack {
            Button {
                viewModel.startScan(for: .document)
            } label: {
                Text("Scan Doc")
            }
            .padding()
            Divider()
                .frame(height: 15)
            Button {
                viewModel.startScan(for: .card)
            } label: {
                Text("Scan Card")
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

#Preview {
    DocScannerDemoView()
}
