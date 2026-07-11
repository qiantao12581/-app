import XCTest
@testable import NutritionTracker

final class DailyNutritionBalanceTests: XCTestCase {
    func testRemainingKeepsDeficitsAndOveragesSeparate() {
        let balance = DailyNutritionBalance(
            target: NutritionValues(
                calories: 0,
                carbohydrates: 100,
                protein: 80,
                fat: 50
            ),
            consumed: NutritionValues(
                calories: 0,
                carbohydrates: 110,
                protein: 60,
                fat: 55
            )
        )

        XCTAssertEqual(balance.remaining.carbohydrates, -10)
        XCTAssertEqual(balance.remaining.protein, 20)
        XCTAssertEqual(balance.remaining.fat, -5)
    }
}
