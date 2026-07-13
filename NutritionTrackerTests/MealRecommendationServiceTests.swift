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
        let foodsByID = Dictionary(uniqueKeysWithValues: fixtureFoods.map { ($0.id, $0) })

        XCTAssertEqual(
            Set(lunch.items.compactMap { foodsByID[$0.foodID]?.category }),
            [.staple, .protein, .vegetable]
        )
        XCTAssertTrue(lunch.items.allSatisfy { $0.quantity.isFinite && $0.quantity > 0 })
        XCTAssertEqual(Set(lunch.items.map(\.id)).count, lunch.items.count)
    }

    func testEveryAutomaticItemUsesItsCatalogDefaultPortionAndExactNutrition() throws {
        let suggestions = MealRecommendationService().suggestions(
            remaining: NutritionValues(
                calories: 600,
                carbohydrates: 100,
                protein: 70,
                fat: 30
            ),
            completedMeals: [.breakfast],
            foods: fixtureFoods
        )

        XCTAssertFalse(suggestions.isEmpty)
        for item in suggestions.flatMap(\.items) {
            let food = try XCTUnwrap(fixtureFoods.first { $0.id == item.foodID })
            let portion = try XCTUnwrap(food.portions.first { $0.id == item.portionID })
            XCTAssertTrue(portion.isDefault)
            XCTAssertNotNil(food.completeNutrition)
            XCTAssertTrue(item.quantity.isFinite)
            XCTAssertGreaterThan(item.quantity, 0)
            XCTAssertTrue(item.nutrition.isComplete)

            let expected = try PortionNutritionCalculator.actual(
                nutrition: food.nutrition,
                basisAmount: food.nutritionBasisAmount,
                basisUnit: food.nutritionBasisUnit,
                quantity: item.quantity,
                portion: portion
            )
            XCTAssertEqual(item.nutrition, expected.nutrition)
        }
    }

    func testAutomaticSuggestionsFollowCompletedMealProgress() {
        let remaining = NutritionValues(
            calories: 600,
            carbohydrates: 100,
            protein: 70,
            fat: 30
        )
        let service = MealRecommendationService()

        XCTAssertEqual(
            service.suggestions(
                remaining: remaining,
                completedMeals: [.breakfast],
                foods: fixtureFoods
            ).map(\.mealType),
            [.lunch, .dinner, .snack]
        )
        XCTAssertEqual(
            service.suggestions(
                remaining: remaining,
                completedMeals: [.breakfast, .lunch],
                foods: fixtureFoods
            ).map(\.mealType),
            [.dinner, .snack]
        )
    }

    func testReleasePieceMilliliterAndServingDefaultsAreReportedWithoutInventedSizes() throws {
        let releaseFoods = try loadReleaseFoods()
        let egg = try releaseFood(id: "cfc-978", in: releaseFoods)
        let milk = try releaseFood(id: "mengniu-telunsu-organic-38", in: releaseFoods)
        let completeMilk = completeFixtureCopy(of: milk)
        let serving = try releaseFood(id: "mcd-cn-cheeseburger", in: releaseFoods)

        let eggItem = try suggestedItem(
            from: [fixtureFoods[0], egg, fixtureFoods[2]],
            meal: .lunch,
            foodID: egg.id
        )
        XCTAssertEqual(eggItem.portionID, "egg-piece")
        XCTAssertEqual(eggItem.quantity.rounded(), eggItem.quantity)

        let milkItem = try suggestedItem(
            from: [completeMilk],
            meal: .snack,
            foodID: milk.id
        )
        XCTAssertEqual(milkItem.portionID, milk.defaultPortion?.id)
        XCTAssertEqual(milk.defaultPortion?.baseUnit, .milliliter)

        let servingItem = try suggestedItem(
            from: [serving],
            meal: .snack,
            foodID: serving.id
        )
        XCTAssertEqual(servingItem.portionID, serving.defaultPortion?.id)
        XCTAssertEqual(serving.defaultPortion?.baseUnit, .serving)
        XCTAssertEqual(servingItem.quantity, 1)
    }

    func testOveragePenaltyStillPrefersCandidateThatStaysWithinDailyRemaining() throws {
        let risky = food(
            id: "risky",
            category: .snack,
            meals: [.snack],
            minimum: 100,
            maximum: 100,
            step: 100,
            carbs: 15,
            protein: 1.5,
            fat: 11
        )
        let safe = food(
            id: "safe",
            category: .snack,
            meals: [.snack],
            minimum: 100,
            maximum: 100,
            step: 100,
            carbs: 45,
            protein: 1.5,
            fat: 1.5
        )

        let snack = try XCTUnwrap(
            MealRecommendationService().suggestions(
                remaining: NutritionValues(
                    calories: 0,
                    carbohydrates: 100,
                    protein: 10,
                    fat: 10
                ),
                completedMeals: [.breakfast, .lunch],
                foods: [risky, safe]
            ).first { $0.mealType == .snack }
        )

        XCTAssertEqual(snack.items.single?.foodID, safe.id)
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
                .allSatisfy { $0.foodID != incompleteProtein.id }
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
        minimum: Double = 50,
        maximum: Double = 150,
        step: Double = 50,
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
            minimumSuggestedGrams: minimum,
            maximumSuggestedGrams: maximum,
            suggestionStepGrams: step
        )
    }

    private func suggestedItem(
        from foods: [FoodReference],
        meal: MealType,
        foodID: String
    ) throws -> MealSuggestionItem {
        let completed = Set(MealType.allCases.filter { $0 != meal && $0 != .snack })
        let suggestions = MealRecommendationService().suggestions(
            remaining: NutritionValues(
                calories: 600,
                carbohydrates: 100,
                protein: 70,
                fat: 30
            ),
            completedMeals: completed,
            foods: foods
        )
        let suggestion = try XCTUnwrap(suggestions.first { $0.mealType == meal })
        return try XCTUnwrap(suggestion.items.first { $0.foodID == foodID })
    }

    private func loadReleaseFoods() throws -> [FoodReference] {
        try FoodDatabaseService(
            data: Data(contentsOf: releaseCatalogURL)
        ).foods
    }

    private func releaseFood(
        id: String,
        in foods: [FoodReference]
    ) throws -> FoodReference {
        try XCTUnwrap(foods.first { $0.id == id })
    }

    private func completeFixtureCopy(of food: FoodReference) -> FoodReference {
        FoodReference(
            id: food.id,
            name: food.name,
            aliases: food.aliases,
            category: food.category,
            suitableMeals: food.suitableMeals,
            nutrition: PartialNutritionValues(
                calories: 60,
                carbohydrates: 5,
                protein: 4,
                fat: 3
            ),
            brandName: food.brandName,
            nutritionBasisAmount: food.nutritionBasisAmount,
            nutritionBasisUnit: food.nutritionBasisUnit,
            portions: food.portions,
            source: food.source,
            display: food.display,
            dataCompleteness: .complete,
            minimumSuggestedGrams: food.minimumSuggestedGrams,
            maximumSuggestedGrams: food.maximumSuggestedGrams,
            suggestionStepGrams: food.suggestionStepGrams
        )
    }

    private var releaseCatalogURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("NutritionTracker")
            .appendingPathComponent("Resources")
            .appendingPathComponent("foods.json")
    }
}

private extension Collection {
    var single: Element? {
        count == 1 ? first : nil
    }
}
