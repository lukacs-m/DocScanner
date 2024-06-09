//
//  RestrictedScanningArea.swift
//  DocScannerDemo
//
//  Created by martin on 04/09/2023.
//

import SwiftUI

public struct RestrictedScanningAreaConfig {
    let overlayColor: Color
    let sizeOfArea: CGSize
    let border: Bool
    let borderCornerRadius: CGFloat
    let borderColor: Color
    let borderColorWidth: CGFloat
    
    public init(overlayColor: Color = .black.opacity(0.5),
                sizeOfArea: CGSize = CGSize(width: 400, height: 350),
                border: Bool = true,
                borderCornerRadius: CGFloat = 5,
                borderColor: Color = .white,
                borderColorWidth: CGFloat = 2) {
        self.overlayColor = overlayColor
        self.sizeOfArea = sizeOfArea
        self.border = border
        self.borderCornerRadius = borderCornerRadius
        self.borderColor = borderColor
        self.borderColorWidth = borderColorWidth
    }
    
    public static var `default`: RestrictedScanningAreaConfig {
        RestrictedScanningAreaConfig()
    }
}

public struct RestrictedScanningArea: View {
    @Binding var regionOfInterest: CGRect?
    let configuration: RestrictedScanningAreaConfig
    
    public init(configuration: RestrictedScanningAreaConfig = .default,
                regionOfInterest: Binding<CGRect?> = Binding.constant(nil)) {
        self.configuration = configuration
        self._regionOfInterest = regionOfInterest
    }
    
    public var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(configuration.overlayColor)
            
            Rectangle()
                .frame(width: configuration.sizeOfArea.width, height: configuration.sizeOfArea.height)
                .blendMode(.destinationOut)
                .overlay(border)
                .background(
                    GeometryReader { geometry -> Color in
                        DispatchQueue.main.async {
                            regionOfInterest = geometry.frame(in: .global)
                        }
                        return Color.clear
                    })
        }
        .compositingGroup()
    }
    
    @ViewBuilder
    var border: some View {
        if configuration.border {
            RoundedRectangle(cornerRadius: configuration.borderCornerRadius)
                .stroke(configuration.borderColor, lineWidth: configuration.borderColorWidth)
        }
    }
}
