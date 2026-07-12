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
