import Foundation

struct FoodReference: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let aliases: [String]
    let category: FoodCategory
    let suitableMeals: [MealType]
    let caloriesPer100Grams: Double
    let carbohydratesPer100Grams: Double
    let proteinPer100Grams: Double
    let fatPer100Grams: Double
    let minimumSuggestedGrams: Double
    let maximumSuggestedGrams: Double
    let suggestionStepGrams: Double

    var nutritionPer100Grams: NutritionValues {
        NutritionValues(
            calories: caloriesPer100Grams,
            carbohydrates: carbohydratesPer100Grams,
            protein: proteinPer100Grams,
            fat: fatPer100Grams
        )
    }

    var hasValidNutritionAndPortion: Bool {
        nutritionPer100Grams.isFiniteAndNonnegative
            && minimumSuggestedGrams.isFinite
            && maximumSuggestedGrams.isFinite
            && suggestionStepGrams.isFinite
            && minimumSuggestedGrams > 0
            && maximumSuggestedGrams >= minimumSuggestedGrams
            && suggestionStepGrams > 0
    }
}
