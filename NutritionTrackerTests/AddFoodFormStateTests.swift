import XCTest
@testable import NutritionTracker

final class AddFoodFormStateTests: XCTestCase {
    private let rice = FoodReference(
        id: "rice-cooked",
        name: "熟米饭",
        aliases: ["米饭"],
        category: .staple,
        suitableMeals: [.lunch, .dinner],
        caloriesPer100Grams: 116,
        carbohydratesPer100Grams: 25.9,
        proteinPer100Grams: 2.6,
        fatPer100Grams: 0.3,
        minimumSuggestedGrams: 50,
        maximumSuggestedGrams: 300,
        suggestionStepGrams: 25
    )

    func testSelectingFoodFillsNameAndPer100Values() {
        var state = AddFoodFormState()

        state.select(food: rice)

        XCTAssertEqual(state.foodName, "熟米饭")
        XCTAssertEqual(state.caloriesPer100Grams, "116.0")
        XCTAssertEqual(state.carbohydratesPer100Grams, "25.9")
        XCTAssertEqual(state.proteinPer100Grams, "2.6")
        XCTAssertEqual(state.fatPer100Grams, "0.3")
    }

    func testActualNutritionUsesEnteredWeight() throws {
        var state = AddFoodFormState()
        state.select(food: rice)
        state.weightGrams = "150"

        let actual = try XCTUnwrap(state.actualNutrition)

        XCTAssertEqual(actual.calories, 174, accuracy: 0.0001)
        XCTAssertEqual(actual.carbohydrates, 38.85, accuracy: 0.0001)
        XCTAssertEqual(actual.protein, 3.9, accuracy: 0.0001)
        XCTAssertEqual(actual.fat, 0.45, accuracy: 0.0001)
    }

    func testValidationRejectsNonnumericWeight() {
        var state = AddFoodFormState()
        state.select(food: rice)
        state.weightGrams = "一百"

        XCTAssertThrowsError(try state.validate()) { error in
            XCTAssertEqual(error as? FoodInputError, .invalidWeight)
        }
    }

    func testResetClearsFoodAndRestoresBreakfast() {
        var state = AddFoodFormState()
        state.select(food: rice)
        state.weightGrams = "150"
        state.mealType = .dinner

        state.reset()

        XCTAssertEqual(state.foodName, "")
        XCTAssertEqual(state.weightGrams, "")
        XCTAssertEqual(state.mealType, .breakfast)
    }
}
