//
//  Page.swift
//  
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation
import UIKit

public struct Page {
    public let pageNumber: Int
    public let image: UIImage
    public let text: [String]

    public init(pageNumber: Int, image: UIImage, text: [String]) {
        self.pageNumber = pageNumber
        self.image = image
        self.text = text
    }
}
