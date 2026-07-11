import XCTest
@testable import NutritionTracker

final class PortionNutritionCalculatorTests: XCTestCase {
    func testTwoEggsUseFiftyGramsPerEgg() throws {
        let result = try PortionNutritionCalculator.actual(
            nutrition: PartialNutritionValues(
                calories: 144, carbohydrates: 0.8, protein: 13.3, fat: 9.5
            ),
            basisAmount: 100,
            basisUnit: .gram,
            quantity: 2,
            portion: FoodPortion(
                id: "egg-piece", name: "个", baseAmount: 50,
                baseUnit: .gram, allowsDecimalQuantity: true, isDefault: true
            )
        )

        XCTAssertEqual(result.baseAmount, 100)
        XCTAssertEqual(result.nutrition.calories, 144)
        XCTAssertEqual(result.nutrition.protein, 13.3)
    }

    func testMilkCartonUsesMilliliterBasis() throws {
        let result = try PortionNutritionCalculator.actual(
            nutrition: PartialNutritionValues(
                calories: 70, carbohydrates: 5, protein: 3.6, fat: 4.4
            ),
            basisAmount: 100,
            basisUnit: .milliliter,
            quantity: 1,
            portion: FoodPortion(
                id: "carton-250", name: "盒", baseAmount: 250,
                baseUnit: .milliliter, allowsDecimalQuantity: true, isDefault: true
            )
        )

        XCTAssertEqual(result.baseAmount, 250)
        XCTAssertEqual(result.nutrition.calories, 175)
    }

    func testMissingOfficialProteinRemainsMissing() throws {
        let result = try PortionNutritionCalculator.actual(
            nutrition: PartialNutritionValues(
                calories: 300, carbohydrates: 30, protein: nil, fat: 12
            ),
            basisAmount: 1,
            basisUnit: .serving,
            quantity: 1,
            portion: .singleServing(name: "个")
        )

        XCTAssertNil(result.nutrition.protein)
    }

    func testRejectsInvalidBasisAmounts() {
        let invalidAmounts: [Double] = [
            0, -1, Double.infinity, -Double.infinity, Double.nan
        ]

        for basisAmount in invalidAmounts {
            assertInvalid(basisAmount: basisAmount)
        }
    }

    func testRejectsInvalidQuantities() {
        let invalidQuantities: [Double] = [
            0, -1, Double.infinity, -Double.infinity, Double.nan
        ]

        for quantity in invalidQuantities {
            assertInvalid(quantity: quantity)
        }
    }

    func testRejectsInvalidPortionBaseAmounts() {
        let invalidAmounts: [Double] = [
            0, -1, Double.infinity, -Double.infinity, Double.nan
        ]

        for portionBaseAmount in invalidAmounts {
            assertInvalid(portionBaseAmount: portionBaseAmount)
        }
    }

    func testRejectsMismatchedUnits() {
        assertInvalid(portionBaseUnit: .milliliter)
    }

    func testRejectsDecimalQuantityWhenPortionRequiresInteger() {
        assertInvalid(quantity: 1.5, allowsDecimalQuantity: false)
    }

    func testRejectsOverflowedActualBaseAmount() {
        assertInvalid(
            quantity: Double.greatestFiniteMagnitude,
            portionBaseAmount: 2
        )
    }

    func testRejectsUnderflowedActualBaseAmount() {
        assertInvalid(
            quantity: Double.leastNonzeroMagnitude,
            portionBaseAmount: 0.5
        )
    }

    func testRejectsOverflowedScalingFactor() {
        assertInvalid(
            basisAmount: Double.leastNonzeroMagnitude,
            quantity: Double.greatestFiniteMagnitude,
            portionBaseAmount: 0.5
        )
    }

    func testRejectsUnderflowedScalingFactor() {
        assertInvalid(
            basisAmount: 2,
            quantity: Double.leastNonzeroMagnitude
        )
    }

    private func assertInvalid(
        basisAmount: Double = 100,
        basisUnit: FoodMeasurementUnit = .gram,
        quantity: Double = 1,
        portionBaseAmount: Double = 1,
        portionBaseUnit: FoodMeasurementUnit = .gram,
        allowsDecimalQuantity: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(
            try PortionNutritionCalculator.actual(
                nutrition: PartialNutritionValues(
                    calories: 100,
                    carbohydrates: 10,
                    protein: 5,
                    fat: 2
                ),
                basisAmount: basisAmount,
                basisUnit: basisUnit,
                quantity: quantity,
                portion: FoodPortion(
                    id: "test-portion",
                    name: "份",
                    baseAmount: portionBaseAmount,
                    baseUnit: portionBaseUnit,
                    allowsDecimalQuantity: allowsDecimalQuantity,
                    isDefault: true
                )
            ),
            file: file,
            line: line
        ) { error in
            XCTAssertEqual(
                error as? PortionInputError,
                .invalidQuantity,
                file: file,
                line: line
            )
            XCTAssertEqual(
                error.localizedDescription,
                "请输入有效的份量",
                file: file,
                line: line
            )
        }
    }
}
