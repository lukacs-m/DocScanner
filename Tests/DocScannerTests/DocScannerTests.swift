import Testing
import UIKit
@testable import DocScanner

@Suite("Card type detection")
struct CardTypeDetectionTests {
    static let cases: [(number: String, expected: CardType)] = [
        ("4" + String(repeating: "1", count: 15), .visa),                  // 16 digits
        ("4" + String(repeating: "1", count: 12), .visa),                  // 13 digits
        ("4" + String(repeating: "1", count: 14), .unknown),               // 15 digits -> invalid
        ("5" + String(repeating: "0", count: 15), .masterCard),            // 16 digits
        ("3" + String(repeating: "4", count: 14), .amex),                  // 15 digits
        ("3" + String(repeating: "0", count: 13), .dinersClubOrCarteBlanche), // 14 digits
        ("6" + String(repeating: "0", count: 15), .discover),              // 16 digits
        ("4111", .unknown),                                                // too short
        ("7" + String(repeating: "0", count: 15), .unknown)               // unknown prefix
    ]

    @Test("Type is derived from leading digit and length", arguments: cases)
    func detectsType(number: String, expected: CardType) {
        #expect(CardType(number: number) == expected)
    }

    @Test("A nil number is unknown")
    func nilNumberIsUnknown() {
        #expect(CardType(number: nil) == .unknown)
    }
}

@Suite("Card industry detection")
struct CardIndustryTests {
    static let cases: [(digit: Character, expected: CardIndustry)] = [
        ("0", .industry),
        ("1", .airlines),
        ("2", .airlinesFinancialAndFuture),
        ("3", .travelAndEntertainment),
        ("4", .bankingAndFinancial),
        ("5", .bankingAndFinancial),
        ("6", .merchandisingAndBanking),
        ("7", .petroleum),
        ("8", .healthcareAndTelecom),
        ("9", .national),
        ("A", .unknown)
    ]

    @Test("Industry is derived from the major industry identifier", arguments: cases)
    func detectsIndustry(digit: Character, expected: CardIndustry) {
        #expect(CardIndustry(firstDigit: digit) == expected)
    }

    @Test("A nil first digit is unknown")
    func nilDigitIsUnknown() {
        #expect(CardIndustry(firstDigit: nil) == .unknown)
    }
}

@Suite("Card number extraction")
struct CardNumberExtractionTests {
    static let cases: [(lines: [String], expected: String?)] = [
        (["4111111111111111"], "4111111111111111"),
        (["4111", "1111", "1111", "1111"], "4111 1111 1111 1111"),
        (["JANE DOE", "4111111111111111", "12/25"], "4111111111111111"),
        (["HELLO", "WORLD"], nil),
        ([], nil),
        (["7111111111111111"], nil)
    ]

    @Test("Extracts a card number from recognized lines", arguments: cases)
    func extractsNumber(lines: [String], expected: String?) {
        #expect(lines.parseCardNumber == expected)
    }
}

@Suite("Expiry date parsing")
struct ExpiryDateParsingTests {
    static let cases: [(input: String, expected: String?)] = [
        ("12/25", "12/25"),
        ("12/2025", "12/2025"),
        ("JANE\n12/25", "12/25"),
        ("1/25", nil),
        ("12/25/99", nil),
        ("AB/CD", nil),
        ("no date here", nil)
    ]

    @Test("Parses MM/YY and MM/YYYY, rejecting malformed input", arguments: cases)
    func parsesExpiry(input: String, expected: String?) {
        #expect(input.parseExpiryDate == expected)
    }
}

@Suite("CVV parsing")
struct CVVParsingTests {
    static let visa = "4111111111111111"
    static let amex = "3" + String(repeating: "4", count: 14)
    static let discover = "6" + String(repeating: "0", count: 15)

    static let cases: [(cvv: String, number: String?, expected: String?)] = [
        ("123", visa, "123"),
        ("1234", amex, "1234"),
        ("12", visa, nil),       // wrong length for visa
        ("12345", amex, nil),    // wrong length for amex
        ("abc", visa, nil),      // not numeric
        ("123", discover, nil),  // discover unsupported
        ("111", visa, nil),      // appears within the card number
        ("123", nil, nil)        // no card number
    ]

    @Test("Parses a CVV against the card type and number", arguments: cases)
    func parsesCVV(cvv: String, number: String?, expected: String?) {
        #expect(cvv.parseCVV(cardNumber: number) == expected)
    }
}

@Suite("Name parsing")
struct NameParsingTests {
    @Test("Accepts a plausible uppercase cardholder name")
    func acceptsValidName() {
        #expect("JANE DOE".parseName == "JANE DOE")
    }

    @Test("Rejects names failing the structural guards", arguments: [
        "jane doe",   // not uppercase
        "JANE",       // single word
        "JANE 2ND",   // contains digits
        "JANE\nDOE"   // contains newline
    ])
    func rejectsInvalidName(input: String) {
        #expect(input.parseName == nil)
    }

    // Regression for the avoid-list bug: card-type names were stored mixed-case but
    // compared against lowercased text, so they never matched. The cached avoid-list
    // must be lowercased.
    @Test("Avoid-list is lowercased so card-brand words actually filter")
    func avoidListIsLowercased() {
        #expect(CardParsingResources.wordsToAvoid.contains("mastercard"))
        #expect(CardParsingResources.wordsToAvoid.contains("visa"))
        #expect(!CardParsingResources.wordsToAvoid.contains("MasterCard"))
    }
}

@Suite("Name regex validation")
struct NameRegexTests {
    static let cases: [(input: String, expected: Bool)] = [
        ("JANE DOE", true),
        ("jane doe", false),
        ("X Y", false)
    ]

    @Test("Matches an uppercase two-part name, rejects others", arguments: cases)
    func validatesNameShape(input: String, expected: Bool) {
        #expect(input.nameRegexChecked == expected)
    }
}

@Suite("CardDetails wiring")
struct CardDetailsTests {
    @Test("Derives type and industry from the number")
    func derivesTypeAndIndustry() {
        let details = CardDetails(numberWithDelimiters: "4111 1111 1111 1111")
        #expect(details.type == .visa)
        #expect(details.industry == .bankingAndFinancial)
    }

    @Test("An empty CardDetails is unknown")
    func emptyIsUnknown() {
        let details = CardDetails()
        #expect(details.type == .unknown)
        #expect(details.industry == .unknown)
    }
}
