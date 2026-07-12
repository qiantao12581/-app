import XCTest
@testable import NutritionTracker

final class AddFoodFormStateTests: XCTestCase {
    private let rice = FoodReference(
        id: "rice-cooked",
        name: "熟米饭",
        aliases: ["米饭"],
        category: .staple,
        suitableMeals: [.lunch, .dinner],
        caloriesPer100Grams: 116,
        carbohydratesPer100Grams: 25.9,
        proteinPer100Grams: 2.6,
        fatPer100Grams: 0.3,
        minimumSuggestedGrams: 50,
        maximumSuggestedGrams: 300,
        suggestionStepGrams: 25
    )

    func testSelectingFoodFillsNameAndPer100Values() {
        var state = AddFoodFormState()

        state.select(food: rice)

        XCTAssertEqual(state.foodName, "熟米饭")
        XCTAssertEqual(state.caloriesPer100Grams, "116.0")
        XCTAssertEqual(state.carbohydratesPer100Grams, "25.9")
        XCTAssertEqual(state.proteinPer100Grams, "2.6")
        XCTAssertEqual(state.fatPer100Grams, "0.3")
    }

    func testSelectingEggDefaultsToPieceAndTwoPiecesCalculateCorrectly() throws {
        var state = AddFoodFormState()

        state.select(food: eggFixture)
        XCTAssertEqual(state.selectedPortionID, "egg-piece")
        state.quantity = "2"

        XCTAssertEqual(state.convertedBaseAmount, 100)
        XCTAssertEqual(state.baseUnit, .gram)
        XCTAssertEqual(try XCTUnwrap(state.actualNutrition?.calories), 144, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(state.actualNutrition?.carbohydrates), 0.7, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(state.actualNutrition?.protein), 13.3, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(state.actualNutrition?.fat), 8.8, accuracy: 0.0001)
    }

    func testSwitchingMilkFromCartonToMillilitersPreservesActualAmount() throws {
        var state = AddFoodFormState()
        state.select(food: milkFixture)
        state.quantity = "1"

        let before = try XCTUnwrap(state.actualNutrition)
        state.selectPortion(id: "milliliter")

        XCTAssertEqual(state.quantity, "250.0")
        XCTAssertEqual(
            try XCTUnwrap(state.convertedBaseAmount),
            250,
            accuracy: 0.0001
        )
        XCTAssertEqual(state.baseUnit, .milliliter)
        XCTAssertEqual(state.actualNutrition, before)
    }

    func testRepeatedCompatiblePortionSwitchesDoNotDriftActualAmount() throws {
        var state = AddFoodFormState()
        state.select(food: precisePortionFixture)
        state.quantity = "1.234"
        let expectedAmount = try XCTUnwrap(state.convertedBaseAmount)
        let expectedNutrition = try XCTUnwrap(state.actualNutrition)

        for _ in 0..<20 {
            state.selectPortion(id: "gram")
            state.selectPortion(id: "bowl")
        }

        XCTAssertEqual(try XCTUnwrap(state.convertedBaseAmount), expectedAmount, accuracy: 0.0000001)
        XCTAssertEqual(state.actualNutrition, expectedNutrition)
    }

    func testInvalidNegativeAndNonfiniteQuantitiesDoNotCalculateNutrition() {
        var state = AddFoodFormState()
        state.select(food: milkFixture)

        for invalidQuantity in ["abc", "-1", "nan", "inf", "1e309"] {
            state.quantity = invalidQuantity

            XCTAssertNil(state.convertedBaseAmount, invalidQuantity)
            XCTAssertNil(state.actualNutrition, invalidQuantity)
            XCTAssertNotNil(state.quantityValidationMessage, invalidQuantity)
        }
    }

    func testDisallowedDecimalQuantityDoesNotCalculateNutrition() {
        var state = AddFoodFormState()
        state.select(food: eggFixture)

        state.quantity = "1.5"

        XCTAssertNil(state.convertedBaseAmount)
        XCTAssertNil(state.actualNutrition)
        XCTAssertNotNil(state.quantityValidationMessage)
    }

    func testIncompleteOfficialNutritionRemainsNilAfterScaling() throws {
        var state = AddFoodFormState()
        state.select(food: incompleteMilkFixture)
        state.quantity = "1"

        let actual = try XCTUnwrap(state.actualNutrition)
        XCTAssertNil(actual.calories)
        XCTAssertNil(actual.carbohydrates)
        XCTAssertEqual(try XCTUnwrap(actual.protein), 9.5, accuracy: 0.0001)
        XCTAssertNil(actual.fat)
        XCTAssertNil(state.actualCompleteNutrition)
    }

    func testManualEntryDefaultsToOneHundredGramsAndUsesEditableNutrition() throws {
        var state = AddFoodFormState()

        XCTAssertFalse(state.isCatalogFood)
        XCTAssertEqual(state.quantity, "100.0")
        XCTAssertEqual(state.selectedPortionID, "gram")
        XCTAssertEqual(state.convertedBaseAmount, 100)
        XCTAssertEqual(state.baseUnit, .gram)

        state.foodName = "自制三明治"
        state.caloriesPer100Grams = "220"
        state.carbohydratesPer100Grams = "30"
        state.proteinPer100Grams = "12"
        state.fatPer100Grams = "6"

        let actual = try XCTUnwrap(state.actualNutrition)
        XCTAssertEqual(try XCTUnwrap(actual.calories), 220)
        XCTAssertEqual(try XCTUnwrap(actual.carbohydrates), 30)
        XCTAssertEqual(try XCTUnwrap(actual.protein), 12)
        XCTAssertEqual(try XCTUnwrap(actual.fat), 6)
        XCTAssertNotNil(state.actualCompleteNutrition)
    }

    func testActualNutritionUsesEnteredManualWeight() throws {
        var state = AddFoodFormState()
        state.foodName = "熟米饭"
        state.caloriesPer100Grams = "116"
        state.carbohydratesPer100Grams = "25.9"
        state.proteinPer100Grams = "2.6"
        state.fatPer100Grams = "0.3"
        state.weightGrams = "150"

        let actual = try XCTUnwrap(state.actualCompleteNutrition)

        XCTAssertEqual(actual.calories, 174, accuracy: 0.0001)
        XCTAssertEqual(actual.carbohydrates, 38.85, accuracy: 0.0001)
        XCTAssertEqual(actual.protein, 3.9, accuracy: 0.0001)
        XCTAssertEqual(actual.fat, 0.45, accuracy: 0.0001)
    }

    func testValidationRejectsNonnumericWeight() {
        var state = AddFoodFormState()
        state.foodName = "熟米饭"
        state.weightGrams = "一百"

        XCTAssertThrowsError(try state.validate()) { error in
            XCTAssertEqual(error as? FoodInputError, .invalidWeight)
        }
    }

    func testResetClearsFoodAndRestoresManualDefaults() {
        var state = AddFoodFormState()
        state.select(food: rice)
        state.quantity = "150"
        state.mealType = .dinner

        state.reset()

        XCTAssertEqual(state.foodName, "")
        XCTAssertEqual(state.quantity, "100.0")
        XCTAssertEqual(state.selectedPortionID, "gram")
        XCTAssertEqual(state.mealType, .breakfast)
        XCTAssertFalse(state.isCatalogFood)
    }

    private var eggFixture: FoodReference {
        reference(
            id: "egg",
            name: "鸡蛋",
            nutrition: PartialNutritionValues(
                calories: 144,
                carbohydrates: 0.7,
                protein: 13.3,
                fat: 8.8
            ),
            portions: [
                FoodPortion(
                    id: "egg-piece",
                    name: "个",
                    baseAmount: 50,
                    baseUnit: .gram,
                    allowsDecimalQuantity: false,
                    isDefault: true
                ),
                FoodPortion(
                    id: "gram",
                    name: "克",
                    baseAmount: 1,
                    baseUnit: .gram,
                    allowsDecimalQuantity: true,
                    isDefault: false
                )
            ]
        )
    }

    private var milkFixture: FoodReference {
        reference(
            id: "milk",
            name: "纯牛奶",
            nutrition: PartialNutritionValues(
                calories: 65,
                carbohydrates: 4.9,
                protein: 3.8,
                fat: 3.8
            ),
            basisUnit: .milliliter,
            portions: [
                FoodPortion(
                    id: "carton-250",
                    name: "盒",
                    baseAmount: 250,
                    baseUnit: .milliliter,
                    allowsDecimalQuantity: true,
                    isDefault: true
                ),
                FoodPortion(
                    id: "milliliter",
                    name: "毫升",
                    baseAmount: 1,
                    baseUnit: .milliliter,
                    allowsDecimalQuantity: true,
                    isDefault: false
                )
            ]
        )
    }

    private var incompleteMilkFixture: FoodReference {
        reference(
            id: "incomplete-milk",
            name: "高蛋白牛奶",
            nutrition: PartialNutritionValues(
                calories: nil,
                carbohydrates: nil,
                protein: 3.8,
                fat: nil
            ),
            basisUnit: .milliliter,
            portions: [
                FoodPortion(
                    id: "carton-250",
                    name: "盒",
                    baseAmount: 250,
                    baseUnit: .milliliter,
                    allowsDecimalQuantity: true,
                    isDefault: true
                )
            ],
            completeness: .missingOfficialFields
        )
    }

    private var precisePortionFixture: FoodReference {
        reference(
            id: "precise",
            name: "精确换算测试",
            nutrition: PartialNutritionValues(
                calories: 100,
                carbohydrates: 10,
                protein: 10,
                fat: 10
            ),
            portions: [
                FoodPortion(
                    id: "bowl",
                    name: "碗",
                    baseAmount: 123.456,
                    baseUnit: .gram,
                    allowsDecimalQuantity: true,
                    isDefault: true
                ),
                FoodPortion(
                    id: "gram",
                    name: "克",
                    baseAmount: 1,
                    baseUnit: .gram,
                    allowsDecimalQuantity: true,
                    isDefault: false
                )
            ]
        )
    }

    private func reference(
        id: String,
        name: String,
        nutrition: PartialNutritionValues,
        basisUnit: FoodMeasurementUnit = .gram,
        portions: [FoodPortion],
        completeness: FoodDataCompleteness = .complete
    ) -> FoodReference {
        FoodReference(
            id: id,
            name: name,
            aliases: [],
            category: .dairy,
            suitableMeals: [.breakfast],
            nutrition: nutrition,
            nutritionBasisAmount: 100,
            nutritionBasisUnit: basisUnit,
            portions: portions,
            source: FoodSourceMetadata(
                type: .userProvided,
                name: "测试",
                url: nil,
                verifiedAt: Date(timeIntervalSince1970: 1),
                specification: "测试规格"
            ),
            display: FoodDisplayMetadata(
                iconKey: "drop",
                colorKey: "blue",
                tags: []
            ),
            dataCompleteness: completeness
        )
    }
}
