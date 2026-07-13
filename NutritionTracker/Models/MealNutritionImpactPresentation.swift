import Foundation

enum MealNutritionImpactPresentation {
    static func amountText(_ value: Double?, unit: String) -> String {
        guard let value else { return "暂无官方数据" }
        return "\(NutritionFormatters.oneDecimal(value)) \(unit)"
    }

    static func remainingText(_ value: Double?, unit: String) -> String {
        guard let value else { return "暂无官方数据" }
        if value > 0 {
            return "还差 \(NutritionFormatters.oneDecimal(value)) \(unit)"
        }
        if value < 0 {
            return "将超出 \(NutritionFormatters.oneDecimal(abs(value))) \(unit)"
        }
        return "已达标"
    }
}
