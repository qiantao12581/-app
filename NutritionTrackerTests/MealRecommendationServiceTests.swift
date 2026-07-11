import Foundation
import XCTest
@testable import NutritionTracker

final class MealRecommendationServiceTests: XCTestCase {
    func testRemainingMealsFollowRecordedBreakfastAndLunch() {
        let service = MealRecommendationService()
        let gap = NutritionValues(
            calories: 0,
            carbohydrates: 120,
            protein: 80,
            fat: 40
        )

        XCTAssertEqual(
            service.remainingMealTypes(
                completedMeals: [.breakfast],
                remaining: gap
            ),
            [.lunch, .dinner, .snack]
        )
        XCTAssertEqual(
            service.remainingMealTypes(
                completedMeals: [.breakfast, .lunch],
                remaining: gap
            ),
            [.dinner, .snack]
        )
    }

    func testNoSuggestionWhenAllMacrosReached() {
        XCTAssertTrue(
            MealRecommendationService().suggestions(
                remaining: NutritionValues(
                    calories: 0,
                    carbohydrates: -5,
                    protein: 0,
                    fat: -2
                ),
                completedMeals: [.breakfast, .lunch, .dinner],
                foods: fixtureFoods
            ).isEmpty
        )
    }

    func testMainMealSuggestionContainsStapleProteinAndVegetable() throws {
        let suggestions = MealRecommendationService().suggestions(
            remaining: NutritionValues(
                calories: 0,
                carbohydrates: 100,
                protein: 70,
                fat: 30
            ),
            completedMeals: [.breakfast],
            foods: fixtureFoods
        )
        let lunch = try XCTUnwrap(suggestions.first { $0.mealType == .lunch })

        XCTAssertEqual(Set(lunch.items.map(\.food.category)), [.staple, .protein, .vegetable])
        XCTAssertTrue(lunch.items.allSatisfy { $0.grams > 0 })
    }

    func testIncompleteFoodIsExcludedFromAutomaticRecommendations() {
        let completeStaplesAndVegetables = fixtureFoods.filter {
            $0.category != .protein
        }
        let incompleteProtein = FoodReference(
            id: "incomplete-protein",
            name: "营养不完整蛋白质",
            aliases: [],
            category: .protein,
            suitableMeals: [.lunch, .dinner],
            nutrition: PartialNutritionValues(
                calories: 100,
                carbohydrates: 2,
                protein: nil,
                fat: 3
            ),
            nutritionBasisAmount: 100,
            nutritionBasisUnit: .gram,
            portions: [FoodPortion(
                id: "gram",
                name: "克",
                baseAmount: 1,
                baseUnit: .gram,
                allowsDecimalQuantity: true,
                isDefault: true
            )],
            source: FoodSourceMetadata(
                type: .officialMenu,
                name: "官方菜单",
                url: nil,
                verifiedAt: Date(timeIntervalSince1970: 0),
                specification: "每100克"
            ),
            display: FoodDisplayMetadata(
                iconKey: "protein",
                colorKey: "protein",
                tags: []
            ),
            dataCompleteness: .missingOfficialFields,
            minimumSuggestedGrams: 50,
            maximumSuggestedGrams: 150,
            suggestionStepGrams: 50
        )

        let suggestions = MealRecommendationService().suggestions(
            remaining: NutritionValues(
                calories: 0,
                carbohydrates: 100,
                protein: 70,
                fat: 30
            ),
            completedMeals: [.breakfast],
            foods: completeStaplesAndVegetables + [incompleteProtein]
        )

        XCTAssertTrue(
            suggestions
                .flatMap(\.items)
                .allSatisfy { $0.food.id != incompleteProtein.id }
        )
    }

    private var fixtureFoods: [FoodReference] {
        [
            food(id: "rice", category: .staple, carbs: 26, protein: 3, fat: 0.3),
            food(id: "chicken", category: .protein, carbs: 0, protein: 31, fat: 3.6),
            food(id: "broccoli", category: .vegetable, carbs: 7, protein: 3, fat: 0.4),
            food(
                id: "yogurt",
                category: .dairy,
                meals: [.snack],
                carbs: 5,
                protein: 4,
                fat: 3
            )
        ]
    }

    private func food(
        id: String,
        category: FoodCategory,
        meals: [MealType] = [.lunch, .dinner],
        carbs: Double,
        protein: Double,
        fat: Double
    ) -> FoodReference {
        FoodReference(
            id: id,
            name: id,
            aliases: [],
            category: category,
            suitableMeals: meals,
            caloriesPer100Grams: carbs * 4 + protein * 4 + fat * 9,
            carbohydratesPer100Grams: carbs,
            proteinPer100Grams: protein,
            fatPer100Grams: fat,
            minimumSuggestedGrams: 50,
            maximumSuggestedGrams: 150,
            suggestionStepGrams: 50
        )
    }
}
