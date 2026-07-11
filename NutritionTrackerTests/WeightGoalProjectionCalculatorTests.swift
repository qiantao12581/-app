import XCTest
@testable import NutritionTracker

final class WeightGoalProjectionCalculatorTests: XCTestCase {
    func testFivePercentMonthlyLossProjectsCompoundDuration() {
        XCTAssertEqual(
            WeightGoalProjectionCalculator.estimatedDays(
                currentWeightKilograms: 100,
                targetWeightKilograms: 90,
                monthlyLossRate: 0.05
            ),
            63
        )
    }

    func testProgressIsClampedFromZeroToOne() {
        XCTAssertEqual(
            WeightGoalProjectionCalculator.progress(
                startWeightKilograms: 100,
                currentWeightKilograms: 95,
                targetWeightKilograms: 90
            ),
            0.5,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            WeightGoalProjectionCalculator.progress(
                startWeightKilograms: 100,
                currentWeightKilograms: 85,
                targetWeightKilograms: 90
            ),
            1
        )
    }

    func testManualDeadlineCanRevealUnsafeRequiredRate() {
        let rate = WeightGoalProjectionCalculator.requiredMonthlyLossRate(
            currentWeightKilograms: 100,
            targetWeightKilograms: 90,
            remainingDays: 30
        )

        XCTAssertGreaterThan(try XCTUnwrap(rate), 0.05)
    }
}
