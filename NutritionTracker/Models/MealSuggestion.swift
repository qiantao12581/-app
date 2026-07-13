import Foundation

struct MealSuggestionItem: Equatable, Identifiable, Sendable {
    let id: String
    let foodID: String
    let quantity: Double
    let portionID: String
    let nutrition: PartialNutritionValues
}

struct MealSuggestion: Equatable, Identifiable, Sendable {
    let mealType: MealType
    let items: [MealSuggestionItem]
    let nutrition: NutritionValues
    let score: Double

    var id: String {
        "\(mealType.rawValue)-" + items.map(\.id).joined(separator: "-")
    }
}
