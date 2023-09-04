//
//  ContentView.swift
//  DocScannerDemo
//
//  Created by Martin Lukacs on 24/08/2023.
//

import SwiftUI
import DocScanner

struct ContentView: View {
    var body: some View {
        TabView {
            DocScannerDemoView()
                .tabItem {
                    Label("Doc Scanner Demo", systemImage: "list.dash")
                }
            
            DataScannerDemoView()
                .tabItem {
                    Label("Data Scanner Demo", systemImage: "square.and.pencil")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
