import XCTest
@testable import NutritionTracker

final class DailySummaryCalculatorTests: XCTestCase {
    func testSumsAllNutritionValues() {
        let total = DailySummaryCalculator.total([
            NutritionValues(
                calories: 174,
                carbohydrates: 38.85,
                protein: 3.9,
                fat: 0.45
            ),
            NutritionValues(
                calories: 144,
                carbohydrates: 0.8,
                protein: 13.3,
                fat: 9.5
            )
        ])

        XCTAssertEqual(total.calories, 318, accuracy: 0.0001)
        XCTAssertEqual(total.carbohydrates, 39.65, accuracy: 0.0001)
        XCTAssertEqual(total.protein, 17.2, accuracy: 0.0001)
        XCTAssertEqual(total.fat, 9.95, accuracy: 0.0001)
    }

    func testEmptyValuesProduceZeroSummary() {
        XCTAssertEqual(DailySummaryCalculator.total([]), .zero)
    }

    func testPartialTotalReturnsKnownLowerBoundAndCompletenessFlags() {
        let total = DailySummaryCalculator.partialTotal([
            PartialNutritionValues(
                calories: 100,
                carbohydrates: 10,
                protein: 5,
                fat: 2
            ),
            PartialNutritionValues(
                calories: 200,
                carbohydrates: 20,
                protein: nil,
                fat: 8
            )
        ])

        XCTAssertEqual(total.lowerBound.calories, 300)
        XCTAssertEqual(total.lowerBound.carbohydrates, 30)
        XCTAssertEqual(total.lowerBound.protein, 5)
        XCTAssertEqual(total.lowerBound.fat, 10)
        XCTAssertTrue(total.caloriesComplete)
        XCTAssertTrue(total.carbohydratesComplete)
        XCTAssertFalse(total.proteinComplete)
        XCTAssertTrue(total.fatComplete)
        XCTAssertTrue(total.hasMissingOfficialData)
    }
}
