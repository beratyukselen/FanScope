import Foundation
import Testing
@testable import FanScopeKit

@Suite("TokenAmountParser")
struct TokenAmountParserTests {
    @Test("Parses 6-decimal Ethereum token amounts")
    func parsesSixDecimalValues() throws {
        let amount = try #require(TokenAmountParser.parse(rawValue: "41296676000000", decimals: 6))
        #expect(amount == 41_296_676.0)
    }

    @Test("Parses 18-decimal amounts larger than Int64 max")
    func parsesLargeEighteenDecimalValues() throws {
        let amount = try #require(TokenAmountParser.parse(rawValue: "9639243000000000000000000", decimals: 18))
        #expect(amount == 9_639_243.0)
    }

    @Test("Rejects empty or non-numeric strings")
    func rejectsInvalidAmounts() {
        #expect(TokenAmountParser.parse(rawValue: "", decimals: 6) == nil)
        #expect(TokenAmountParser.parse(rawValue: "not-a-number", decimals: 18) == nil)
        #expect(TokenAmountParser.parse(rawValue: "100", decimals: -1) == nil)
    }

    @Test("Parses ISO-8601 dates with and without fractional seconds")
    func parsesISO8601Variants() throws {
        let fractional = try #require(TokenAmountParser.parseISO8601("2026-11-21T19:03:59.000000Z"))
        let standard = try #require(TokenAmountParser.parseISO8601("2026-11-21T19:03:59Z"))
        #expect(fractional == standard)
    }

    @Test("Parses Unix timestamp strings")
    func parsesUnixTimestamps() throws {
        let date = try #require(TokenAmountParser.parseUnixTimestamp("1795259593"))
        #expect(date == Date(timeIntervalSince1970: 1_795_259_593))
        #expect(TokenAmountParser.parseUnixTimestamp("abc") == nil)
    }
}
