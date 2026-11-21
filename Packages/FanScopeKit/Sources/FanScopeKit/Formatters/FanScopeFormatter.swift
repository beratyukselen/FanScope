import Foundation

public enum FanScopeFormatter {
    private static let trLocale = Locale(identifier: "tr_TR")

    public static func tryPrice(_ value: Decimal) -> String {
        let doubleValue = NSDecimalNumber(decimal: value).doubleValue
        let fractionDigits = abs(doubleValue) < 1 ? 4 : 2

        return value.formatted(
            .number
                .locale(trLocale)
                .precision(.fractionLength(fractionDigits))
        ) + " ₺"
    }

    public static func signedPercentage(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        let formatted = value.formatted(
            .number
                .locale(trLocale)
                .precision(.fractionLength(2))
        )
        return "\(sign)\(formatted)%"
    }

    public static func compactTokenAmount(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        switch absValue {
        case 1_000_000_000...:
            return "\(sign)\(formatCompact(absValue / 1_000_000_000))B"
        case 1_000_000...:
            return "\(sign)\(formatCompact(absValue / 1_000_000))M"
        case 1_000...:
            return "\(sign)\(formatCompact(absValue / 1_000))K"
        default:
            return value.formatted(
                .number
                    .locale(trLocale)
                    .precision(.fractionLength(0...2))
            )
        }
    }

    public static func shortenedAddress(_ address: String) -> String {
        guard address.count > 12 else { return address }
        let prefix = address.prefix(6)
        let suffix = address.suffix(4)
        return "\(prefix)...\(suffix)"
    }

    private static func formatCompact(_ scaled: Double) -> String {
        scaled.formatted(
            .number
                .locale(trLocale)
                .precision(.fractionLength(0...2))
        )
    }
}
