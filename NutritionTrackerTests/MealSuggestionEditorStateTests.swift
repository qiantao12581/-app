import Foundation
import XCTest
@testable import NutritionTracker

final class MealSuggestionEditorStateTests: XCTestCase {
    func testChangingReleaseEggFromOneToTwoPiecesUpdatesMealAndSignedDayBalance() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        var state = try editor(food: egg, grams: 50, catalog: foods)
        let itemID = try XCTUnwrap(state.items.first?.id)
        let eggCalories = try XCTUnwrap(egg.nutrition.calories)

        try state.selectPortion(itemID: itemID, portionID: "large-egg")
        try state.updateQuantity(itemID: itemID, text: "2")

        XCTAssertEqual(state.items[0].selectedPortionID, "large-egg")
        XCTAssertEqual(state.items[0].calculation?.baseAmount, 100)
        XCTAssertEqual(
            try XCTUnwrap(state.mealNutrition.calories),
            eggCalories,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            try XCTUnwrap(state.mealNutrition.carbohydrates),
            0.7,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            try XCTUnwrap(state.mealNutrition.protein),
            12.6,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            try XCTUnwrap(state.mealNutrition.fat),
            9.5,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            try XCTUnwrap(state.remainingAfterMeal.calories),
            100 - eggCalories,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            try XCTUnwrap(state.remainingAfterMeal.protein),
            7.4,
            accuracy: 0.000_001
        )
        XCTAssertLessThan(try XCTUnwrap(state.remainingAfterMeal.calories), 0)
    }

    func testSelectingCompatiblePortionPreservesActualIntake() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        var state = try editor(food: egg, grams: 50, catalog: foods)
        let itemID = try XCTUnwrap(state.items.first?.id)
        let before = try XCTUnwrap(state.items.first?.calculation)

        try state.selectPortion(itemID: itemID, portionID: "large-egg")

        let item = try XCTUnwrap(state.items.first)
        XCTAssertEqual(item.selectedPortionID, "large-egg")
        XCTAssertEqual(Double(item.quantityText), 1)
        XCTAssertEqual(item.calculation?.baseAmount, before.baseAmount)
        XCTAssertEqual(item.calculation?.nutrition, before.nutrition)
    }

    func testReplacingProteinKeepsIdentityAndUsesReplacementDefaultPortion() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        let soybean = try food(id: "cfc-326", in: foods)
        var state = try editor(food: egg, grams: 50, catalog: foods)
        let originalID = try XCTUnwrap(state.items.first?.id)

        try state.replace(itemID: originalID, withFoodID: soybean.id)

        let replacement = try XCTUnwrap(state.items.first)
        XCTAssertEqual(replacement.id, originalID)
        XCTAssertEqual(replacement.food.id, soybean.id)
        XCTAssertEqual(replacement.food.category, .protein)
        XCTAssertEqual(replacement.selectedPortionID, soybean.defaultPortion?.id)
        XCTAssertEqual(replacement.quantityText, "1")
    }

    func testAddingOriginalFoodAfterReplacementCreatesUniqueRowIdentity() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        let soybean = try food(id: "cfc-326", in: foods)
        var state = try editor(food: egg, grams: 50, catalog: foods)
        let originalID = try XCTUnwrap(state.items.first?.id)

        try state.replace(itemID: originalID, withFoodID: soybean.id)
        try state.add(foodID: egg.id)

        XCTAssertEqual(state.items.map(\.food.id), [soybean.id, egg.id])
        XCTAssertEqual(Set(state.items.map(\.id)).count, 2)
        XCTAssertEqual(state.items.first?.id, originalID)
        XCTAssertNotEqual(state.items.last?.id, originalID)
        XCTAssertTrue(state.canSave)
    }

    func testReplacingWithFoodAlreadyInDraftFailsWithoutPartialMutation() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        let soybean = try food(id: "cfc-326", in: foods)
        var state = try editor(food: egg, grams: 50, catalog: foods)
        let eggItemID = try XCTUnwrap(state.items.first?.id)
        try state.add(foodID: soybean.id)
        let before = state

        XCTAssertThrowsError(
            try state.replace(itemID: eggItemID, withFoodID: soybean.id)
        ) { error in
            XCTAssertEqual(
                error as? MealSuggestionEditorError,
                .duplicateItemID(soybean.id)
            )
        }
        XCTAssertEqual(state, before)
    }

    func testReplacementEnforcesCategoryByDefaultWithoutPartialMutation() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        let vegetable = try XCTUnwrap(foods.first { $0.category == .vegetable })
        var state = try editor(food: egg, grams: 50, catalog: foods)
        let before = state
        let itemID = try XCTUnwrap(state.items.first?.id)

        XCTAssertThrowsError(
            try state.replace(itemID: itemID, withFoodID: vegetable.id)
        ) { error in
            XCTAssertEqual(
                error as? MealSuggestionEditorError,
                .categoryMismatch(expected: .protein, actual: .vegetable)
            )
        }
        XCTAssertEqual(state, before)
    }

    func testReplacementCanIntentionallyChangeCategory() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        let vegetable = try XCTUnwrap(foods.first { $0.category == .vegetable })
        var state = try editor(food: egg, grams: 50, catalog: foods)
        let itemID = try XCTUnwrap(state.items.first?.id)

        try state.replace(
            itemID: itemID,
            withFoodID: vegetable.id,
            allowCategoryChange: true
        )

        XCTAssertEqual(state.items.first?.id, itemID)
        XCTAssertEqual(state.items.first?.food.id, vegetable.id)
        XCTAssertEqual(state.items.first?.selectedPortionID, vegetable.defaultPortion?.id)
    }

    func testAddingAndRemovingItemRecalculatesThroughSharedTotals() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        let vegetable = try XCTUnwrap(foods.first { $0.category == .vegetable })
        var state = try editor(food: egg, grams: 50, catalog: foods)
        let caloriesBefore = try XCTUnwrap(state.mealNutrition.calories)

        try state.add(foodID: vegetable.id)

        let addedID = try XCTUnwrap(state.items.last?.id)
        XCTAssertGreaterThan(try XCTUnwrap(state.mealNutrition.calories), caloriesBefore)
        state.remove(itemID: addedID)
        XCTAssertEqual(state.items.count, 1)
        XCTAssertEqual(
            try XCTUnwrap(state.mealNutrition.calories),
            caloriesBefore,
            accuracy: 0.000_001
        )
    }

    func testInvalidQuantitiesSetChineseValidationAndClearCalculation() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        let invalidTexts = ["", "0", "-1", "nan", "inf", "1.5"]

        for text in invalidTexts {
            var state = try editor(food: egg, grams: 50, catalog: foods)
            let itemID = try XCTUnwrap(state.items.first?.id)

            try state.updateQuantity(itemID: itemID, text: text)

            XCTAssertEqual(state.items.first?.quantityText, text)
            XCTAssertEqual(state.items.first?.validationMessage, "请输入有效的份量")
            XCTAssertNil(state.items.first?.calculation)
            XCTAssertNil(state.mealNutrition.calories)
            XCTAssertNil(state.remainingAfterMeal.calories)
            XCTAssertFalse(state.canSave)
        }
    }

    func testIncompleteOfficialFoodPreservesMissingFieldsWithoutContributingZero() throws {
        let incompleteMilk = incompleteOfficialMilk
        let foods = [incompleteMilk]
        var state = emptyEditor(catalog: foods)

        try state.add(foodID: incompleteMilk.id)

        let itemNutrition = try XCTUnwrap(state.items.first?.calculation?.nutrition)
        XCTAssertNil(itemNutrition.calories)
        XCTAssertNil(itemNutrition.carbohydrates)
        XCTAssertEqual(try XCTUnwrap(itemNutrition.protein), 9, accuracy: 0.000_001)
        XCTAssertNil(itemNutrition.fat)
        XCTAssertNil(state.mealNutrition.calories)
        XCTAssertNil(state.mealNutrition.carbohydrates)
        XCTAssertEqual(
            try XCTUnwrap(state.mealNutrition.protein),
            9,
            accuracy: 0.000_001
        )
        XCTAssertNil(state.mealNutrition.fat)
        XCTAssertNil(state.remainingAfterMeal.calories)
        XCTAssertEqual(
            try XCTUnwrap(state.remainingAfterMeal.protein),
            11,
            accuracy: 0.000_001
        )
        XCTAssertTrue(state.hasIncompleteNutrition)
    }

    func testUnknownFoodAddFailsWithoutPartialMutation() throws {
        let foods = try releaseFoods()
        var state = emptyEditor(catalog: foods)
        let before = state

        XCTAssertThrowsError(try state.add(foodID: "missing")) { error in
            XCTAssertEqual(error as? MealSuggestionEditorError, .foodNotFound("missing"))
        }
        XCTAssertEqual(state, before)
    }

    func testUnknownFoodReplacementFailsWithoutPartialMutation() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        var state = try editor(food: egg, grams: 50, catalog: foods)
        let before = state
        let itemID = try XCTUnwrap(state.items.first?.id)

        XCTAssertThrowsError(
            try state.replace(itemID: itemID, withFoodID: "missing")
        ) { error in
            XCTAssertEqual(error as? MealSuggestionEditorError, .foodNotFound("missing"))
        }
        XCTAssertEqual(state, before)
    }

    func testUnknownPortionFailsWithoutPartialMutation() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        var state = try editor(food: egg, grams: 50, catalog: foods)
        let before = state
        let itemID = try XCTUnwrap(state.items.first?.id)

        XCTAssertThrowsError(
            try state.selectPortion(itemID: itemID, portionID: "missing")
        ) { error in
            XCTAssertEqual(
                error as? MealSuggestionEditorError,
                .portionNotFound(foodID: egg.id, portionID: "missing")
            )
        }
        XCTAssertEqual(state, before)
    }

    func testDuplicateAddedItemIDFailsWithoutPartialMutation() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        var state = emptyEditor(catalog: foods)
        try state.add(foodID: egg.id)
        let before = state

        XCTAssertThrowsError(try state.add(foodID: egg.id)) { error in
            XCTAssertEqual(error as? MealSuggestionEditorError, .duplicateItemID(egg.id))
        }
        XCTAssertEqual(state, before)
    }

    func testUnknownItemQuantityUpdateFailsWithoutPartialMutation() throws {
        let foods = try releaseFoods()
        var state = emptyEditor(catalog: foods)
        let before = state

        XCTAssertThrowsError(
            try state.updateQuantity(itemID: "missing", text: "2")
        ) { error in
            XCTAssertEqual(error as? MealSuggestionEditorError, .itemNotFound("missing"))
        }
        XCTAssertEqual(state, before)
    }

    func testEmptyDraftCannotSaveAndCompleteValidDraftCanSave() throws {
        let foods = try releaseFoods()
        var state = emptyEditor(catalog: foods)
        XCTAssertTrue(state.items.isEmpty)
        XCTAssertFalse(state.canSave)

        try state.add(foodID: "egg-chicken-whole")

        XCTAssertTrue(state.canSave)
        XCTAssertFalse(state.hasIncompleteNutrition)
        XCTAssertEqual(state.draft.mealType, .breakfast)
        XCTAssertEqual(state.draft.items, state.items)
    }

    func testMissingDailyFieldStaysNilWhileKnownFieldsRemainSigned() throws {
        let foods = try releaseFoods()
        let egg = try food(id: "egg-chicken-whole", in: foods)
        let suggestion = try suggestion(food: egg, grams: 50)
        let state = MealSuggestionEditorState(
            suggestion: suggestion,
            dailyRemainingBeforeMeal: PartialNutritionValues(
                calories: nil,
                carbohydrates: 0,
                protein: 1,
                fat: 1
            ),
            catalog: foods
        )

        XCTAssertNil(state.remainingAfterMeal.calories)
        XCTAssertLessThan(try XCTUnwrap(state.remainingAfterMeal.protein), 0)
        XCTAssertLessThan(try XCTUnwrap(state.remainingAfterMeal.fat), 0)
    }

    private func editor(
        food: FoodReference,
        grams: Double,
        catalog: [FoodReference]
    ) throws -> MealSuggestionEditorState {
        MealSuggestionEditorState(
            suggestion: try suggestion(food: food, grams: grams),
            dailyRemainingBeforeMeal: dailyRemaining,
            catalog: catalog
        )
    }

    private func emptyEditor(catalog: [FoodReference]) -> MealSuggestionEditorState {
        MealSuggestionEditorState(
            suggestion: MealSuggestion(
                mealType: .breakfast,
                items: [],
                nutrition: .zero,
                score: 0
            ),
            dailyRemainingBeforeMeal: dailyRemaining,
            catalog: catalog
        )
    }

    private func suggestion(food: FoodReference, grams: Double) throws -> MealSuggestion {
        let portion = try XCTUnwrap(food.defaultPortion)
        let calculation = try PortionNutritionCalculator.actual(
            nutrition: food.nutrition,
            basisAmount: food.nutritionBasisAmount,
            basisUnit: food.nutritionBasisUnit,
            quantity: grams / portion.baseAmount,
            portion: portion
        )
        let nutrition = NutritionValues(
            calories: try XCTUnwrap(calculation.nutrition.calories),
            carbohydrates: try XCTUnwrap(calculation.nutrition.carbohydrates),
            protein: try XCTUnwrap(calculation.nutrition.protein),
            fat: try XCTUnwrap(calculation.nutrition.fat)
        )
        return MealSuggestion(
            mealType: .breakfast,
            items: [MealSuggestionItem(
                id: food.id,
                foodID: food.id,
                quantity: calculation.quantity,
                portionID: portion.id,
                nutrition: calculation.nutrition
            )],
            nutrition: nutrition,
            score: 0
        )
    }

    private func releaseFoods() throws -> [FoodReference] {
        try FoodDatabaseService(data: Data(contentsOf: releaseCatalogURL)).foods
    }

    private var incompleteOfficialMilk: FoodReference {
        FoodReference(
            id: "incomplete-official-milk",
            name: "官方营养字段不完整牛奶",
            aliases: [],
            category: .dairy,
            suitableMeals: [.breakfast, .snack],
            nutrition: PartialNutritionValues(
                calories: nil,
                carbohydrates: nil,
                protein: 3.6,
                fat: nil
            ),
            nutritionBasisAmount: 100,
            nutritionBasisUnit: .milliliter,
            portions: [FoodPortion(
                id: "carton-250",
                name: "盒",
                baseAmount: 250,
                baseUnit: .milliliter,
                allowsDecimalQuantity: false,
                isDefault: true
            )],
            source: FoodSourceMetadata(
                type: .officialMenu,
                name: "官方营养说明",
                url: nil,
                verifiedAt: Date(timeIntervalSince1970: 0),
                specification: "每100毫升"
            ),
            display: FoodDisplayMetadata(
                iconKey: "drop.fill",
                colorKey: "blue",
                tags: []
            ),
            dataCompleteness: .missingOfficialFields,
            minimumSuggestedGrams: 250,
            maximumSuggestedGrams: 250,
            suggestionStepGrams: 250
        )
    }

    private func food(id: String, in foods: [FoodReference]) throws -> FoodReference {
        try XCTUnwrap(foods.first { $0.id == id })
    }

    private var dailyRemaining: PartialNutritionValues {
        PartialNutritionValues(
            calories: 100,
            carbohydrates: 40,
            protein: 20,
            fat: 5
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
