import Foundation

enum NutritionFormatters {
    static func oneDecimal(_ value: Double) -> String {
        String(
            format: "%.1f",
            locale: Locale(identifier: "en_US_POSIX"),
            value
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
