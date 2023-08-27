//
//  ContentView.swift
//  DocScannerDemo
//
//  Created by Martin Lukacs on 24/08/2023.
//

import SwiftUI
import DocScanner

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

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

private extension ContentView {
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

private extension ContentView {
    var emptyRow: some View {
        VStack {
            Spacer()
            Text("No content scanned detected. Please start scanning away")
                .font(.title2)
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
}

private extension ContentView {
    func cardRow(for cardDetails: CardDetails) -> some View {
        VStack {
            Spacer()
            if let cardImage = cardDetails.image {
                Image(uiImage: cardImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding()
            }
          
            Section("Card content") {
                VStack(alignment: .leading) {
                    Text("**Card owner**: \(cardDetails.name ?? "Unknown")")
                    Text("**Card number**: \(cardDetails.number ?? "Unknown")")
                    Text("**Card expiration date**: \(cardDetails.expiryDate ?? "Unknown")")
                    Text("**Card type**: \(cardDetails.type.rawValue)")
                    Text("**Card industry**: \(cardDetails.industry.rawValue)")
                    Text("**Card CVV**: \(cardDetails.cvvNumber ?? "Unknown")")
                }
            }
            .padding(.bottom, 50)
            Spacer()
        }
    }
}

private extension ContentView {
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

private extension ContentView {
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
