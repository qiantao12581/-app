import Foundation

/// 与 Core Data 解耦的饮食记录快照，供“常吃食物”等纯业务逻辑使用。
struct FoodRecordSnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    let foodName: String
    let catalogFoodID: String?
    let mealType: MealType
    let inputMethod: InputMethod
    let quantity: Double
    let portionName: String
    let baseAmount: Double
    let baseUnit: FoodMeasurementUnit
    let nutrition: PartialNutritionValues
    let createdAt: Date

    /// 内置食物按目录 ID 合并，历史手动食物按名称、单位和份量名称合并。
    var stableFoodKey: String {
        let normalizedCatalogID = normalized(catalogFoodID)
        if !normalizedCatalogID.isEmpty {
            return "catalog:\(normalizedCatalogID)"
        }
        return [
            "manual",
            normalized(foodName),
            baseUnit.rawValue,
            normalized(portionName)
        ].joined(separator: "|")
    }

    /// 只有能够安全恢复数量并重新计算营养的历史记录才能用于快捷添加。
    var isReusableForQuickAdd: Bool {
        guard quantity.isFinite, quantity > 0,
              baseAmount.isFinite, baseAmount > 0,
              !normalized(foodName).isEmpty,
              !normalized(portionName).isEmpty else {
            return false
        }

        let nutrients = [
            nutrition.calories,
            nutrition.carbohydrates,
            nutrition.protein,
            nutrition.fat
        ]
        let knownNutrients = nutrients.compactMap { $0 }
        guard !knownNutrients.isEmpty,
              knownNutrients.allSatisfy({ $0.isFinite && $0 >= 0 }) else {
            return false
        }

        // 无目录 ID 的历史食物只能依赖记录本身恢复数据，因此四项营养必须完整。
        if normalized(catalogFoodID).isEmpty {
            return nutrition.isComplete
        }
        return true
    }

    private func normalized(_ value: String?) -> String {
        (value ?? "")
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: Locale(identifier: "zh_Hans_CN")
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { !$0.isWhitespace && !$0.isPunctuation }
    }
}
