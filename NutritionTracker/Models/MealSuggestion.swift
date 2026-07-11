import Foundation

struct MealSuggestionItem: Equatable, Identifiable, Sendable {
    let food: FoodReference
    let grams: Double
    let nutrition: NutritionValues

    var id: String { "\(food.id)-\(grams)" }
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
