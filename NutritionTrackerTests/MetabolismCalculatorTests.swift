import XCTest
@testable import NutritionTracker

final class MetabolismCalculatorTests: XCTestCase {
    func testMifflinStJeorForMaleAndFemale() {
        XCTAssertEqual(
            MetabolismCalculator.estimatedBMR(
                weightKilograms: 80,
                heightCentimeters: 180,
                age: 30,
                sex: .male
            ),
            1780,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            MetabolismCalculator.estimatedBMR(
                weightKilograms: 80,
                heightCentimeters: 180,
                age: 30,
                sex: .female
            ),
            1614,
            accuracy: 0.0001
        )
    }

    func testManualBMRHasPriority() {
        XCTAssertEqual(
            MetabolismCalculator.resolvedBMR(
                manualBMR: 1650,
                estimatedBMR: 1780
            ),
            1650
        )
    }

    func testActivityLevelsUseNonExerciseFactors() {
        XCTAssertEqual(ActivityLevel.sedentary.factor, 1.20)
        XCTAssertEqual(ActivityLevel.light.factor, 1.30)
        XCTAssertEqual(ActivityLevel.moderate.factor, 1.45)
        XCTAssertEqual(ActivityLevel.heavy.factor, 1.60)
    }
}
