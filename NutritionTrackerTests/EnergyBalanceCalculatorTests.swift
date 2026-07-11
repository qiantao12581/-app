import XCTest
@testable import NutritionTracker

final class EnergyBalanceCalculatorTests: XCTestCase {
    func testExerciseIsAddedSeparatelyToDailyExpenditure() {
        let balance = DailyEnergyBalance(
            basalMetabolicRate: 1780,
            activityFactor: 1.20,
            exerciseCalories: 400,
            intakeCalories: 2000
        )

        XCTAssertEqual(balance.baselineExpenditure, 2136, accuracy: 0.0001)
        XCTAssertEqual(balance.totalExpenditure, 2536, accuracy: 0.0001)
        XCTAssertEqual(balance.calorieDeficit, 536, accuracy: 0.0001)
    }

    func testNegativeDeficitRepresentsSurplus() {
        let balance = DailyEnergyBalance(
            basalMetabolicRate: 1500,
            activityFactor: 1.20,
            exerciseCalories: 0,
            intakeCalories: 2000
        )

        XCTAssertEqual(balance.calorieDeficit, -200, accuracy: 0.0001)
    }
}
