import Foundation

struct NutritionValues: Codable, Equatable, Sendable {
    var calories: Double
    var carbohydrates: Double
    var protein: Double
    var fat: Double

    static let zero = NutritionValues(
        calories: 0,
        carbohydrates: 0,
        protein: 0,
        fat: 0
    )

    static func + (lhs: NutritionValues, rhs: NutritionValues) -> NutritionValues {
        NutritionValues(
            calories: lhs.calories + rhs.calories,
            carbohydrates: lhs.carbohydrates + rhs.carbohydrates,
            protein: lhs.protein + rhs.protein,
            fat: lhs.fat + rhs.fat
        )
    }

    func scaled(by factor: Double) -> NutritionValues {
        NutritionValues(
            calories: calories * factor,
            carbohydrates: carbohydrates * factor,
            protein: protein * factor,
            fat: fat * factor
        )
    }

    var isFiniteAndNonnegative: Bool {
        [calories, carbohydrates, protein, fat]
            .allSatisfy { $0.isFinite && $0 >= 0 }
    }
}
