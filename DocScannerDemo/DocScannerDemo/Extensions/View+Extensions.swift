//
//  View+Extensions.swift
//  DocScannerDemo
//
//  Created by martin on 04/09/2023.
//

import DocScanner
import SwiftUI

extension View {
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
