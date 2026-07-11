import Foundation

enum DailySummaryCalculator {
    static func total(_ values: [NutritionValues]) -> NutritionValues {
        values.reduce(.zero, +)
    }
}
