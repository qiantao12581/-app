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

    func testIncompleteCaloriesPresentLowerBoundAndDisableExactDeficit() {
        let total = PartialNutritionTotal(
            lowerBound: NutritionValues(
                calories: 450,
                carbohydrates: 40,
                protein: 25,
                fat: 12
            ),
            caloriesComplete: false,
            carbohydratesComplete: true,
            proteinComplete: true,
            fatComplete: true
        )

        let presentation = TodayNutritionPresentation(total: total)

        XCTAssertEqual(presentation.calorieIntake, .atLeast(450))
        XCTAssertFalse(presentation.canPresentExactEnergyBalance)
        XCTAssertEqual(
            presentation.energyBalanceUnavailableMessage,
            "部分食物记录缺少热量数据，暂时无法计算准确的热量缺口。"
        )
    }

    func testIncompleteMacroDisablesPreciseMealSuggestions() {
        let total = PartialNutritionTotal(
            lowerBound: NutritionValues(
                calories: 450,
                carbohydrates: 40,
                protein: 25,
                fat: 12
            ),
            caloriesComplete: true,
            carbohydratesComplete: true,
            proteinComplete: false,
            fatComplete: true
        )

        let presentation = TodayNutritionPresentation(total: total)

        XCTAssertFalse(presentation.canGenerateMealSuggestions)
        XCTAssertEqual(
            presentation.mealSuggestionsUnavailableMessage,
            "部分食物记录缺少三大营养素数据，暂时无法生成准确的餐次建议。"
        )
    }

    func testCompleteTotalsRetainExactEnergyBalanceAndMealSuggestions() {
        let total = PartialNutritionTotal(
            lowerBound: NutritionValues(
                calories: 450,
                carbohydrates: 40,
                protein: 25,
                fat: 12
            ),
            caloriesComplete: true,
            carbohydratesComplete: true,
            proteinComplete: true,
            fatComplete: true
        )

        let presentation = TodayNutritionPresentation(total: total)

        XCTAssertEqual(presentation.calorieIntake, .exact(450))
        XCTAssertTrue(presentation.canPresentExactEnergyBalance)
        XCTAssertNil(presentation.energyBalanceUnavailableMessage)
        XCTAssertTrue(presentation.canGenerateMealSuggestions)
        XCTAssertNil(presentation.mealSuggestionsUnavailableMessage)
    }
}
