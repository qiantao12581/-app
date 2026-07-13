import Foundation

struct PartialNutritionTotal: Equatable, Sendable {
    let lowerBound: NutritionValues
    let caloriesComplete: Bool
    let carbohydratesComplete: Bool
    let proteinComplete: Bool
    let fatComplete: Bool

    var hasMissingOfficialData: Bool {
        !caloriesComplete
            || !carbohydratesComplete
            || !proteinComplete
            || !fatComplete
    }

    static let zero = PartialNutritionTotal(
        lowerBound: .zero,
        caloriesComplete: true,
        carbohydratesComplete: true,
        proteinComplete: true,
        fatComplete: true
    )
}

enum NutritionAmountPresentation: Equatable, Sendable {
    case exact(Double)
    case atLeast(Double)

    var value: Double {
        switch self {
        case let .exact(value), let .atLeast(value): return value
        }
    }

    var prefix: String {
        switch self {
        case .exact: return ""
        case .atLeast: return "至少 "
        }
    }
}

struct TodayNutritionPresentation: Equatable, Sendable {
    let calorieIntake: NutritionAmountPresentation
    let energyBalanceUnavailableMessage: String?
    let mealSuggestionsUnavailableMessage: String?

    init(total: PartialNutritionTotal) {
        calorieIntake = total.caloriesComplete
            ? .exact(total.lowerBound.calories)
            : .atLeast(total.lowerBound.calories)
        energyBalanceUnavailableMessage = total.caloriesComplete
            ? nil
            : "部分食物记录缺少热量数据，暂时无法计算准确的热量缺口。"
        let macrosComplete = total.carbohydratesComplete
            && total.proteinComplete
            && total.fatComplete
        mealSuggestionsUnavailableMessage = macrosComplete
            ? nil
            : "部分食物记录缺少三大营养素数据，暂时无法生成准确的餐次建议。"
    }

    var canPresentExactEnergyBalance: Bool {
        energyBalanceUnavailableMessage == nil
    }

    var canGenerateMealSuggestions: Bool {
        mealSuggestionsUnavailableMessage == nil
    }
}

enum DailySummaryCalculator {
    static func total(_ values: [NutritionValues]) -> NutritionValues {
        values.reduce(.zero, +)
    }

    static func partialTotal(
        _ values: [PartialNutritionValues]
    ) -> PartialNutritionTotal {
        values.reduce(.zero) { result, value in
            PartialNutritionTotal(
                lowerBound: result.lowerBound + NutritionValues(
                    calories: value.calories ?? 0,
                    carbohydrates: value.carbohydrates ?? 0,
                    protein: value.protein ?? 0,
                    fat: value.fat ?? 0
                ),
                caloriesComplete: result.caloriesComplete && value.calories != nil,
                carbohydratesComplete: result.carbohydratesComplete
                    && value.carbohydrates != nil,
                proteinComplete: result.proteinComplete && value.protein != nil,
                fatComplete: result.fatComplete && value.fat != nil
            )
        }
    }
}
