import XCTest
@testable import NutritionTracker

final class InputValidatorTests: XCTestCase {
    func testRejectsBlankFoodName() {
        XCTAssertThrowsError(
            try InputValidator.validateFood(
                name: "  ",
                weightGrams: 100,
                per100Grams: .zero
            )
        ) { error in
            XCTAssertEqual(error as? FoodInputError, .missingName)
        }
    }

    func testRejectsNonPositiveWeight() {
        for weight in [0.0, -1.0] {
            XCTAssertThrowsError(
                try InputValidator.validateFood(
                    name: "熟米饭",
                    weightGrams: weight,
                    per100Grams: .zero
                )
            ) { error in
                XCTAssertEqual(error as? FoodInputError, .invalidWeight)
            }
        }
    }

    func testRejectsNonFiniteWeight() {
        XCTAssertThrowsError(
            try InputValidator.validateFood(
                name: "熟米饭",
                weightGrams: .infinity,
                per100Grams: .zero
            )
        ) { error in
            XCTAssertEqual(error as? FoodInputError, .invalidWeight)
        }
    }

    func testRejectsNegativeNutrition() {
        let invalid = NutritionValues(
            calories: 100,
            carbohydrates: -1,
            protein: 2,
            fat: 3
        )

        XCTAssertThrowsError(
            try InputValidator.validateFood(
                name: "熟米饭",
                weightGrams: 100,
                per100Grams: invalid
            )
        ) { error in
            XCTAssertEqual(error as? FoodInputError, .invalidNutrition)
        }
    }
}
