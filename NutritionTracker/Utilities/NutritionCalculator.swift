import Foundation

enum NutritionCalculator {
    static func actual(
        per100Grams: NutritionValues,
        weightGrams: Double
    ) -> NutritionValues {
        per100Grams.scaled(by: weightGrams / 100)
    }
}
