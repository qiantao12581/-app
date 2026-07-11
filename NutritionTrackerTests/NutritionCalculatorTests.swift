import XCTest
@testable import NutritionTracker

final class NutritionCalculatorTests: XCTestCase {
    func testScalesEachNutrientFromPer100Grams() {
        let per100 = NutritionValues(
            calories: 116,
            carbohydrates: 25.9,
            protein: 2.6,
            fat: 0.3
        )

        let actual = NutritionCalculator.actual(
            per100Grams: per100,
            weightGrams: 150
        )

        XCTAssertEqual(actual.calories, 174, accuracy: 0.0001)
        XCTAssertEqual(actual.carbohydrates, 38.85, accuracy: 0.0001)
        XCTAssertEqual(actual.protein, 3.9, accuracy: 0.0001)
        XCTAssertEqual(actual.fat, 0.45, accuracy: 0.0001)
    }

    func testAddsNutritionValuesForDailyTotals() {
        let breakfast = NutritionValues(
            calories: 144,
            carbohydrates: 0.8,
            protein: 13.3,
            fat: 9.5
        )
        let lunch = NutritionValues(
            calories: 174,
            carbohydrates: 38.85,
            protein: 3.9,
            fat: 0.45
        )

        let total = breakfast + lunch

        XCTAssertEqual(total.calories, 318, accuracy: 0.0001)
        XCTAssertEqual(total.carbohydrates, 39.65, accuracy: 0.0001)
        XCTAssertEqual(total.protein, 17.2, accuracy: 0.0001)
        XCTAssertEqual(total.fat, 9.95, accuracy: 0.0001)
    }
}
