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

            HStack {
                Button {
                    viewModel.scanType = .document
                    viewModel.showScanner.toggle()
                } label: {
                    Text("Scan Doc")
                }

                Button {
                    viewModel.scanType = .card
                    viewModel.showScanner.toggle()
                } label: {
                    Text("Scan Card")
                }
            }
        }
        .sheet(isPresented: $viewModel.showScanner) {
            DocScanner(with: viewModel.interpretor,
                       scanResult: $viewModel.scanResponse) { results in
                print(results)
            }
                       .edgesIgnoringSafeArea(.all)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
