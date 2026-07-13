import XCTest
@testable import NutritionTracker

final class MealNutritionImpactPresentationTests: XCTestCase {
    func testAmountTextKeepsOneDecimalAndNeverTurnsMissingDataIntoZero() {
        XCTAssertEqual(
            MealNutritionImpactPresentation.amountText(12.34, unit: "克"),
            "12.3 克"
        )
        XCTAssertEqual(
            MealNutritionImpactPresentation.amountText(nil, unit: "克"),
            "暂无官方数据"
        )
    }

    func testRemainingTextSeparatesGapOverageReachedAndMissingData() {
        XCTAssertEqual(
            MealNutritionImpactPresentation.remainingText(12.34, unit: "克"),
            "还差 12.3 克"
        )
        XCTAssertEqual(
            MealNutritionImpactPresentation.remainingText(-2.36, unit: "克"),
            "将超出 2.4 克"
        )
        XCTAssertEqual(
            MealNutritionImpactPresentation.remainingText(0, unit: "克"),
            "已达标"
        )
        XCTAssertEqual(
            MealNutritionImpactPresentation.remainingText(nil, unit: "克"),
            "暂无官方数据"
        )
    }
}
