import CoreData
import XCTest
@testable import NutritionTracker

final class MealSuggestionBatchStoreTests: XCTestCase {
    func testValidDinnerSavesEveryItemInOneBatchWithCompleteMetadata() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let draft = MealSuggestionDraft(
            mealType: .dinner,
            items: [
                try makeItem(id: "rice", name: "米饭", quantity: 150),
                try makeItem(id: "chicken", name: "鸡胸肉", quantity: 120),
                try makeItem(
                    id: "broccoli",
                    name: "西兰花",
                    quantity: 180,
                    nutrition: PartialNutritionValues(
                        calories: 35,
                        carbohydrates: 7,
                        protein: 3,
                        fat: nil
                    )
                )
            ]
        )

        let records = try MealSuggestionBatchStore().save(
            draft,
            date: date,
            context: context
        )
        let persisted = try context.fetch(FoodRecord.fetchRequest())

        XCTAssertEqual(records.count, 3)
        XCTAssertEqual(Set(records.map(\.objectID)), Set(persisted.map(\.objectID)))
        XCTAssertEqual(Set(records.compactMap(\.catalogFoodID)), ["rice", "chicken", "broccoli"])
        XCTAssertEqual(Set(records.map(\.id)).count, 3)
        XCTAssertTrue(records.allSatisfy { $0.mealType == .dinner })
        XCTAssertTrue(records.allSatisfy { $0.inputMethod == .manual })
        XCTAssertTrue(records.allSatisfy { $0.createdAt == date })
        XCTAssertTrue(records.allSatisfy { $0.baseUnit == .gram })
        XCTAssertTrue(records.allSatisfy { $0.portionName == "克" })

        let broccoli = try XCTUnwrap(records.first { $0.catalogFoodID == "broccoli" })
        XCTAssertFalse(broccoli.fatKnown)
        XCTAssertEqual(broccoli.fat, 0)
        XCTAssertTrue(broccoli.caloriesKnown)
        XCTAssertEqual(broccoli.quantity, 180)
        XCTAssertEqual(broccoli.baseAmount, 180)
        XCTAssertEqual(broccoli.weightGrams, 180)
    }

    func testInvalidLaterItemThrowsBeforeAnyRecordIsInserted() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let valid = try makeItem(id: "rice", name: "米饭", quantity: 100)
        var invalid = try makeItem(id: "chicken", name: "鸡胸肉", quantity: 100)
        invalid.quantityText = "-1"
        let draft = MealSuggestionDraft(mealType: .lunch, items: [valid, invalid])

        XCTAssertThrowsError(
            try MealSuggestionBatchStore().save(
                draft,
                date: Date(),
                context: context
            )
        ) { error in
            XCTAssertEqual(error as? MealDraftError, .invalidItem("鸡胸肉"))
        }

        XCTAssertFalse(context.hasChanges)
        XCTAssertTrue(try context.fetch(FoodRecord.fetchRequest()).isEmpty)
    }

    func testEmptyDraftAndMissingFoodIDAreRejected() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let store = MealSuggestionBatchStore()

        XCTAssertThrowsError(
            try store.save(
                MealSuggestionDraft(mealType: .snack, items: []),
                date: Date(),
                context: context
            )
        ) { error in
            XCTAssertEqual(error as? MealDraftError, .emptyMeal)
            XCTAssertEqual(error.localizedDescription, "这餐还没有食物")
        }

        let missingID = try makeItem(id: "   ", name: "无标识食物", quantity: 1)
        XCTAssertThrowsError(
            try store.save(
                MealSuggestionDraft(mealType: .snack, items: [missingID]),
                date: Date(),
                context: context
            )
        ) { error in
            XCTAssertEqual(error as? MealDraftError, .invalidItem("无标识食物"))
            XCTAssertEqual(error.localizedDescription, "请检查食物“无标识食物”的份量")
        }
        XCTAssertFalse(context.hasChanges)
    }

    func testContextSaveFailureRollsBackWholeMealAndLeavesDraftUnchanged() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        _ = FoodRecord(context: context) // 故意缺少必填字段，让同一次 context.save 失败。
        let draft = MealSuggestionDraft(
            mealType: .dinner,
            items: [
                try makeItem(id: "rice", name: "米饭", quantity: 150),
                try makeItem(id: "chicken", name: "鸡胸肉", quantity: 120),
                try makeItem(id: "broccoli", name: "西兰花", quantity: 180)
            ]
        )
        let snapshot = draft

        XCTAssertThrowsError(
            try MealSuggestionBatchStore().save(
                draft,
                date: Date(),
                inputMethod: .photo,
                context: context
            )
        )

        XCTAssertEqual(draft, snapshot)
        XCTAssertFalse(context.hasChanges)
        XCTAssertTrue(try context.fetch(FoodRecord.fetchRequest()).isEmpty)
    }

    private func makeItem(
        id: String,
        name: String,
        quantity: Double,
        nutrition: PartialNutritionValues = PartialNutritionValues(
            calories: 120,
            carbohydrates: 20,
            protein: 8,
            fat: 2
        )
    ) throws -> MealSuggestionDraftItem {
        let food = makeFood(id: id, name: name, nutrition: nutrition)
        let portion = try XCTUnwrap(food.defaultPortion)
        let calculation = try PortionNutritionCalculator.actual(
            nutrition: food.nutrition,
            basisAmount: food.nutritionBasisAmount,
            basisUnit: food.nutritionBasisUnit,
            quantity: quantity,
            portion: portion
        )
        return MealSuggestionDraftItem(
            id: id,
            food: food,
            quantityText: String(quantity),
            selectedPortionID: portion.id,
            calculation: calculation,
            validationMessage: nil
        )
    }

    private func makeFood(
        id: String,
        name: String,
        nutrition: PartialNutritionValues
    ) -> FoodReference {
        FoodReference(
            id: id,
            name: name,
            aliases: [],
            category: .staple,
            suitableMeals: [.lunch, .dinner, .snack],
            nutrition: nutrition,
            nutritionBasisAmount: 100,
            nutritionBasisUnit: .gram,
            portions: [FoodPortion(
                id: "gram",
                name: "克",
                baseAmount: 1,
                baseUnit: .gram,
                allowsDecimalQuantity: true,
                isDefault: true
            )],
            source: FoodSourceMetadata(
                type: .userProvided,
                name: "测试数据",
                url: nil,
                verifiedAt: Date(timeIntervalSince1970: 0),
                specification: "每100克"
            ),
            display: FoodDisplayMetadata(
                iconKey: "staple",
                colorKey: "staple",
                tags: []
            ),
            dataCompleteness: nutrition.isComplete ? .complete : .missingOfficialFields,
            minimumSuggestedGrams: 1,
            maximumSuggestedGrams: 500,
            suggestionStepGrams: 1
        )
    }
}
