import Foundation

enum NutritionFormatters {
    static func oneDecimal(_ value: Double) -> String {
        let decimal = Decimal(
            string: String(value),
            locale: Locale(identifier: "en_US_POSIX")
        ) ?? Decimal(value)
        var source = decimal
        var rounded = Decimal()
        NSDecimalRound(&rounded, &source, 1, .plain)

        return String(
            format: "%.1f",
            locale: Locale(identifier: "en_US_POSIX"),
            NSDecimalNumber(decimal: rounded).doubleValue
        )
    }

    static func decimal(from text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "，", with: ".")
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}
