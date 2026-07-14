import Foundation

struct FoodNutritionRowPresentation: Equatable, Sendable {
    let name: String
    let brandName: String?
    let evidenceBadge: String
    let basisAndCalories: String
    let macros: String
    let accessibilityLabel: String

    init(food: FoodReference) {
        name = food.name
        brandName = food.brandName
        evidenceBadge = food.source.badgeText

        let amount = Self.formattedBasisAmount(food.nutritionBasisAmount)
        let unit = food.nutritionBasisUnit.chineseName
        basisAndCalories = "每\(amount)\(unit) · "
            + Self.formatted(food.nutrition.calories, unit: "千卡")
        macros = "碳水 \(Self.formatted(food.nutrition.carbohydrates, unit: "克")) · "
            + "蛋白质 \(Self.formatted(food.nutrition.protein, unit: "克")) · "
            + "脂肪 \(Self.formatted(food.nutrition.fat, unit: "克"))"
        accessibilityLabel = [
            name,
            brandName,
            evidenceBadge,
            basisAndCalories,
            macros
        ]
        .compactMap { $0 }
        .joined(separator: "，")
    }

    private static func formattedBasisAmount(_ value: Double) -> String {
        if value.isFinite, value.rounded() == value {
            return String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), value)
        }
        return NutritionFormatters.oneDecimal(value)
    }

    private static func formatted(_ value: Double?, unit: String) -> String {
        guard let value, value.isFinite, value >= 0 else { return "暂无数据" }
        return "\(NutritionFormatters.oneDecimal(value))\(unit)"
    }
}
