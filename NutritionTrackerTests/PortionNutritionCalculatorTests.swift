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
}
