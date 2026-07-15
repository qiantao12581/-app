import Foundation
import XCTest
@testable import NutritionTracker

final class QuickFoodQuantityStateTests: XCTestCase {
    func testCatalogSelectionRestoresLastMatchingPortionAndQuantity() throws {
        let eggFood = try releaseFood(id: "egg-chicken-whole")
        let selection = QuickFoodSelection.catalog(
            food: eggFood,
            remembered: candidate(
                quantity: 2,
                portionName: "  个（大号）  ",
                baseAmount: 100,
                baseUnit: .gram
            )
        )

        let state = QuickFoodQuantityState(
            selection: selection,
            mealType: .breakfast
        )

        XCTAssertEqual(state.selectedPortionID, "large-egg")
        XCTAssertEqual(state.quantityText, "2.0")
        XCTAssertEqual(state.baseAmount, 100)
    }

    func testCatalogSelectionFallsBackToDefaultPortionWhenRememberedPortionIsMissing() throws {
        let eggFood = try releaseFood(id: "egg-chicken-whole")
        let selection = QuickFoodSelection.catalog(
            food: eggFood,
            remembered: candidate(
                quantity: 2,
                portionName: "旧版鸡蛋份量",
                baseAmount: 100,
                baseUnit: .gram
            )
        )

        let state = QuickFoodQuantityState(
            selection: selection,
            mealType: .breakfast
        )

        XCTAssertEqual(state.selectedPortionID, eggFood.defaultPortion?.id)
        XCTAssertEqual(state.quantityText, "1.0")
    }

    func testManualHistoricalSelectionScalesSnapshotAfterQuantityChange() throws {
        let manualRiceCandidate = candidate(
            foodName: "手动米饭",
            catalogID: nil,
            quantity: 1,
            portionName: "100克",
            baseAmount: 100,
            baseUnit: .gram,
            nutrition: PartialNutritionValues(
                calories: 116,
                carbohydrates: 25.9,
                protein: 2.6,
                fat: 0.3
            )
        )
        let selection = try XCTUnwrap(
            QuickFoodSelection.historicalManual(candidate: manualRiceCandidate)
        )
        var state = QuickFoodQuantityState(
            selection: selection,
            mealType: .lunch
        )

        state.updateQuantity("1.5")

        XCTAssertNil(state.catalogFoodIDForSave)
        XCTAssertEqual(try XCTUnwrap(state.baseAmount), 150, accuracy: 0.000_001)
        XCTAssertEqual(
            try XCTUnwrap(state.nutrition?.calories),
            174,
            accuracy: 0.000_001
        )
        XCTAssertNoThrow(try state.validate())
    }

    func testManualHistoricalSelectionRejectsIncompleteNutrition() {
        let incomplete = candidate(
            foodName: "营养不完整的手动食物",
            catalogID: nil,
            quantity: 1,
            portionName: "100克",
            baseAmount: 100,
            baseUnit: .gram,
            nutrition: PartialNutritionValues(
                calories: 100,
                carbohydrates: 20,
                protein: nil,
                fat: 1
            )
        )

        XCTAssertNil(QuickFoodSelection.historicalManual(candidate: incomplete))
    }

    func testManualHistoricalSelectionRejectsZeroPreviousQuantity() {
        let zeroQuantity = candidate(
            foodName: "无效手动食物",
            catalogID: nil,
            quantity: 0,
            portionName: "100克",
            baseAmount: 100,
            baseUnit: .gram
        )

        XCTAssertNil(QuickFoodSelection.historicalManual(candidate: zeroQuantity))
    }

    func testValidationRejectsInvalidUserQuantity() throws {
        let manual = candidate(
            foodName: "手动米饭",
            catalogID: nil,
            quantity: 1,
            portionName: "100克",
            baseAmount: 100,
            baseUnit: .gram
        )
        let selection = try XCTUnwrap(
            QuickFoodSelection.historicalManual(candidate: manual)
        )
        var state = QuickFoodQuantityState(
            selection: selection,
            mealType: .dinner
        )

        state.updateQuantity("-1")

        XCTAssertThrowsError(try state.validate()) { error in
            XCTAssertEqual(error as? FoodInputError, .invalidQuantity)
        }
    }

    private func releaseFood(id: String) throws -> FoodReference {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("NutritionTracker")
            .appendingPathComponent("Resources")
            .appendingPathComponent("foods.json")
        return try XCTUnwrap(
            FoodDatabaseService(data: Data(contentsOf: url)).foods.first {
                $0.id == id
            }
        )
    }

    private func candidate(
        foodName: String = "鸡蛋（全蛋，生鲜）",
        catalogID: String? = "egg-chicken-whole",
        quantity: Double,
        portionName: String,
        baseAmount: Double,
        baseUnit: FoodMeasurementUnit,
        nutrition: PartialNutritionValues = PartialNutritionValues(
            calories: 143,
            carbohydrates: 0.7,
            protein: 12.6,
            fat: 9.5
        )
    ) -> FrequentFoodCandidate {
        let record = FoodRecordSnapshot(
            id: UUID(),
            foodName: foodName,
            catalogFoodID: catalogID,
            mealType: .breakfast,
            inputMethod: .manual,
            quantity: quantity,
            portionName: portionName,
            baseAmount: baseAmount,
            baseUnit: baseUnit,
            nutrition: nutrition,
            createdAt: Date(timeIntervalSince1970: 1_768_478_400)
        )
        return FrequentFoodCandidate(
            id: record.stableFoodKey,
            foodName: record.foodName,
            catalogFoodID: record.catalogFoodID,
            useCount: 1,
            lastRecord: record
        )
    }
}
