import Foundation

enum FoodInputError: LocalizedError, Equatable {
    case missingName
    case invalidWeight
    case invalidNutrition

    var errorDescription: String? {
        switch self {
        case .missingName:
            return "请输入食物名称"
        case .invalidWeight:
            return "重量必须大于 0 克"
        case .invalidNutrition:
            return "营养数据必须是非负数"
        }
    }
}

enum InputValidator {
    static func validateFood(
        name: String,
        weightGrams: Double,
        per100Grams: NutritionValues
    ) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoodInputError.missingName
        }
        guard weightGrams.isFinite, weightGrams > 0 else {
            throw FoodInputError.invalidWeight
        }
        guard per100Grams.isFiniteAndNonnegative else {
            throw FoodInputError.invalidNutrition
        }
    }
}
