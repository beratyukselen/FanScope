import Foundation

public enum TokenAmountParser {
    /// Parses a base-10 integer string (such as a uint256 ERC-20 balance) and scales it by token decimals.
    public static func parse(rawValue: String, decimals: Int) -> Double? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, decimals >= 0, let rawDecimal = Decimal(string: trimmed) else {
            return nil
        }
        let scaled = Decimal(sign: rawDecimal.sign, exponent: -decimals, significand: rawDecimal)
        return NSDecimalNumber(decimal: scaled).doubleValue
    }

    public static func parseISO8601(_ value: String) -> Date? {
        let fractionalStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        if let date = try? fractionalStyle.parse(value) {
            return date
        }
        let standardStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: false)
        return try? standardStyle.parse(value)
    }

    public static func parseUnixTimestamp(_ value: String) -> Date? {
        guard let seconds = TimeInterval(value) else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }
}
