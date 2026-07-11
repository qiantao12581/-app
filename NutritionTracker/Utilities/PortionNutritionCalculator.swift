import Foundation

struct PortionCalculationResult: Equatable, Sendable {
    let quantity: Double
    let portionName: String
    let baseAmount: Double
    let baseUnit: FoodMeasurementUnit
    let nutrition: PartialNutritionValues
}

enum PortionInputError: LocalizedError, Equatable {
    case invalidQuantity

    var errorDescription: String? {
        switch self {
        case .invalidQuantity:
            return "请输入有效的份量"
        }
    }
}

enum PortionNutritionCalculator {
    static func actual(
        nutrition: PartialNutritionValues,
        basisAmount: Double,
        basisUnit: FoodMeasurementUnit,
        quantity: Double,
        portion: FoodPortion
    ) throws -> PortionCalculationResult {
        guard basisAmount.isFinite,
              basisAmount > 0,
              quantity.isFinite,
              quantity > 0,
              portion.baseAmount.isFinite,
              portion.baseAmount > 0,
              portion.baseUnit == basisUnit,
              portion.allowsDecimalQuantity || quantity.rounded() == quantity else {
            throw PortionInputError.invalidQuantity
        }

        let actualBaseAmount = quantity * portion.baseAmount
        guard actualBaseAmount.isFinite, actualBaseAmount > 0 else {
            throw PortionInputError.invalidQuantity
        }

        let scalingFactor = actualBaseAmount / basisAmount
        guard scalingFactor.isFinite, scalingFactor > 0 else {
            throw PortionInputError.invalidQuantity
        }

        return PortionCalculationResult(
            quantity: quantity,
            portionName: portion.name,
            baseAmount: actualBaseAmount,
            baseUnit: portion.baseUnit,
            nutrition: nutrition.scaled(by: scalingFactor)
        )
    }
}
