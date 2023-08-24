//
//  CardDetails.swift
//  
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation
import UIKit

public struct CardDetails: Hashable, Identifiable, ScanResponse {
    public let number: String?
    public let name: String?
    public let expiryDate: String?
    public let cvcNumber: String?
    public let type: CardType
    public let industry: CardIndustry
    public let image: UIImage?

    public init(image: UIImage? = nil,
                numberWithDelimiters: String? = nil,
                name: String? = nil,
                expiryDate: String? = nil,
                cvcNumber: String? = nil) {
        self.number = numberWithDelimiters
        self.name = name
        self.expiryDate = expiryDate
        self.cvcNumber = cvcNumber
        self.type = CardType(number: numberWithDelimiters?.replacingOccurrences(of: " ", with: ""))
        self.industry = .init(firstDigit: numberWithDelimiters?.first)
        self.image = image
    }

    public var id: Int { hashValue }

    static var empty: CardDetails {
        CardDetails()
    }
}

public enum CardType: String, CaseIterable, Identifiable {
    case masterCard = "MasterCard"
    case visa = "Visa"
    case amex = "Amex"
    case discover = "Discover"
    case dinersClubOrCarteBlanche = "Diner's Club/Carte Blanche"
    case unknown

    public init(number: String?) {
        guard let count = number?.count, count >= 14 else {
            self = .unknown
            return
        }
        switch number?.first {
        case "3":
            if count == 15 {
                self = .amex
            } else if count == 14 {
                self = .dinersClubOrCarteBlanche
            } else {
                self = .unknown
            }
        case "4": self = (count == 13 || count == 16) ? .visa : .unknown
        case "5": self = count == 16 ? .masterCard : .unknown
        case "6": self = count == 16 ? .discover : .unknown
        default: self = .unknown
        }
    }

    public var id: Int { hashValue }
}

public enum CardIndustry: String, CaseIterable, Identifiable {
    case industry = "ISO/TC 68 and other industry assignments"
    case airlines = "Airlines"
    case airlinesFinancialAndFuture = "Airlines, financial and other future industry assignments"
    case travelAndEntertainment = "Travel and entertainment"
    case bankingAndFinancial = "Banking and financial"
    case merchandisingAndBanking = "Merchandising and banking/financial"
    case petroleum = "Petroleum and other future industry assignments"
    case healthcareAndTelecom = "Healthcare, telecommunications and other future industry assignments"
    case national = "For assignment by national standards bodies"
    case unknown

    public init(firstDigit: String.Element?) {
        switch firstDigit {
        case "0": self = .industry
        case "1": self = .airlines
        case "2": self = .airlinesFinancialAndFuture
        case "3": self = .travelAndEntertainment
        case "4", "5": self = .bankingAndFinancial
        case "6": self = .merchandisingAndBanking
        case "7": self = .petroleum
        case "8": self = .healthcareAndTelecom
        case "9": self = .national
        default: self = .unknown
        }
    }

    public var id: Int { hashValue }
}
