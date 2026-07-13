import Foundation

struct MealSuggestionDraftItem: Identifiable, Equatable, Sendable {
    let id: String
    var food: FoodReference
    var quantityText: String
    var selectedPortionID: String
    var calculation: PortionCalculationResult?
    var validationMessage: String?
}

struct MealSuggestionDraft: Equatable, Sendable {
    var mealType: MealType
    var items: [MealSuggestionDraftItem]
}
