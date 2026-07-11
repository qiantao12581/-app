import Foundation

struct PartialNutritionValues: Codable, Equatable, Sendable {
    var calories: Double?
    var carbohydrates: Double?
    var protein: Double?
    var fat: Double?

    var isComplete: Bool {
        calories != nil && carbohydrates != nil && protein != nil && fat != nil
    }

    func scaled(by factor: Double) -> PartialNutritionValues {
        PartialNutritionValues(
            calories: calories.map { $0 * factor },
            carbohydrates: carbohydrates.map { $0 * factor },
            protein: protein.map { $0 * factor },
            fat: fat.map { $0 * factor }
        )
    }
}
