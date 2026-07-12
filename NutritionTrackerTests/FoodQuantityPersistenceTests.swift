import CoreData
import XCTest
@testable import NutritionTracker

final class FoodQuantityPersistenceTests: XCTestCase {
    func testSavingTwoEggsPersistsQuantityMetadataAndKnownFlags() throws {
        let context = PersistenceController(inMemory: true).container.viewContext

        let record = try FoodRecordStore().save(
            foodName: "鸡蛋",
            mealType: .breakfast,
            inputMethod: .manual,
            quantity: 2,
            portionName: "个",
            baseAmount: 100,
            baseUnit: .gram,
            catalogFoodID: "egg",
            nutrition: PartialNutritionValues(
                calories: 144,
                carbohydrates: 0.8,
                protein: 13.3,
                fat: 9.5
            ),
            context: context
        )

        context.refresh(record, mergeChanges: false)
        XCTAssertEqual(record.quantity, 2)
        XCTAssertEqual(record.portionName, "个")
        XCTAssertEqual(record.baseAmount, 100)
        XCTAssertEqual(record.baseUnit, .gram)
        XCTAssertEqual(record.catalogFoodID, "egg")
        XCTAssertTrue(record.caloriesKnown)
        XCTAssertTrue(record.carbohydratesKnown)
        XCTAssertTrue(record.proteinKnown)
        XCTAssertTrue(record.fatKnown)
    }

    func testIncompleteOfficialNutritionRemainsUnknownInsteadOfOfficialZero() throws {
        let context = PersistenceController(inMemory: true).container.viewContext

        let record = try FoodRecordStore().save(
            foodName: "官方食品",
            mealType: .lunch,
            inputMethod: .manual,
            quantity: 1,
            portionName: "份",
            baseAmount: 1,
            baseUnit: .serving,
            catalogFoodID: "official-partial",
            nutrition: PartialNutritionValues(
                calories: 300,
                carbohydrates: 30,
                protein: nil,
                fat: 12
            ),
            context: context
        )

        XCTAssertFalse(record.proteinKnown)
        XCTAssertNil(record.partialNutritionValues.protein)
        XCTAssertEqual(record.partialNutritionValues.calories, 300)
    }

    func testLegacyDefaultsPresentFullyKnownGramQuantity() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let record = makeLegacyRecord(context: context)
        try context.save()
        context.refresh(record, mergeChanges: false)

        XCTAssertTrue(record.caloriesKnown)
        XCTAssertTrue(record.carbohydratesKnown)
        XCTAssertTrue(record.proteinKnown)
        XCTAssertTrue(record.fatKnown)
        XCTAssertEqual(record.presentedQuantity, 175)
        XCTAssertEqual(record.presentedBaseAmount, 175)
        XCTAssertEqual(record.baseUnit, .gram)
        XCTAssertEqual(record.presentedPortionName, "克")
    }

    func testCustomFoodCRUDUsesUUIDAndUpsertsInOneContext() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let store = CustomFoodStore()
        let id = UUID()

        let created = try store.save(makeDraft(id: id, name: "自制燕麦杯"), context: context)
        XCTAssertEqual(created.id, id)
        XCTAssertEqual(try store.food(id: id, context: context)?.name, "自制燕麦杯")

        let updated = try store.save(makeDraft(id: id, name: "自制酸奶燕麦杯"), context: context)
        XCTAssertEqual(updated.objectID, created.objectID)
        XCTAssertEqual(try store.foods(context: context).count, 1)
        XCTAssertEqual(updated.foodReference.nutrition.protein, 8)
        XCTAssertEqual(updated.foodReference.source.type, .userProvided)

        try store.delete(id: id, context: context)
        XCTAssertNil(try store.food(id: id, context: context))
    }

    func testCustomFoodValidationRejectsInvalidDrafts() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let store = CustomFoodStore()

        assertRejects(makeDraft(name: "   "), using: store, context: context)
        assertRejects(makeDraft(basisAmount: .infinity), using: store, context: context)
        assertRejects(makeDraft(basisAmount: 0), using: store, context: context)
        assertRejects(
            makeDraft(nutrition: PartialNutritionValues(
                calories: nil, carbohydrates: nil, protein: nil, fat: nil
            )),
            using: store,
            context: context
        )
        assertRejects(
            makeDraft(nutrition: PartialNutritionValues(
                calories: 100, carbohydrates: -1, protein: nil, fat: nil
            )),
            using: store,
            context: context
        )
        assertRejects(makeDraft(portions: []), using: store, context: context)
        assertRejects(
            makeDraft(portions: [portion(isDefault: false)]),
            using: store,
            context: context
        )
        assertRejects(
            makeDraft(portions: [portion(isDefault: true), portion(id: "second", isDefault: true)]),
            using: store,
            context: context
        )
        assertRejects(
            makeDraft(portions: [portion(baseAmount: .nan)]),
            using: store,
            context: context
        )
        assertRejects(
            makeDraft(portions: [portion(baseUnit: .milliliter)]),
            using: store,
            context: context
        )
    }

    func testFailedCustomFoodSaveRollsBackInsertedObject() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        _ = FoodRecord(context: context) // Required fields intentionally unset.

        XCTAssertThrowsError(
            try CustomFoodStore().save(makeDraft(name: "不应残留"), context: context)
        )
        XCTAssertFalse(context.hasChanges)
        XCTAssertTrue(try context.fetch(CustomFood.fetchRequest()).isEmpty)
    }

    private func assertRejects(
        _ draft: CustomFoodDraft,
        using store: CustomFoodStore,
        context: NSManagedObjectContext,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try store.save(draft, context: context), file: file, line: line)
        XCTAssertFalse(context.hasChanges, file: file, line: line)
    }

    private func makeDraft(
        id: UUID = UUID(),
        name: String = "自制燕麦杯",
        basisAmount: Double = 100,
        nutrition: PartialNutritionValues = PartialNutritionValues(
            calories: 180, carbohydrates: nil, protein: 8, fat: 5
        ),
        portions: [FoodPortion]? = nil
    ) -> CustomFoodDraft {
        CustomFoodDraft(
            id: id,
            name: name,
            brandName: "家庭配方",
            aliases: ["燕麦"],
            nutrition: nutrition,
            nutritionBasisAmount: basisAmount,
            nutritionBasisUnit: .gram,
            portions: portions ?? [portion()],
            iconKey: "staple",
            colorKey: "staple"
        )
    }

    private func portion(
        id: String = "gram",
        baseAmount: Double = 1,
        baseUnit: FoodMeasurementUnit = .gram,
        isDefault: Bool = true
    ) -> FoodPortion {
        FoodPortion(
            id: id,
            name: "克",
            baseAmount: baseAmount,
            baseUnit: baseUnit,
            allowsDecimalQuantity: true,
            isDefault: isDefault
        )
    }

    private func makeLegacyRecord(context: NSManagedObjectContext) -> FoodRecord {
        let record = FoodRecord(context: context)
        record.id = UUID()
        record.foodName = "旧记录"
        record.weightGrams = 175
        record.calories = 200
        record.carbohydrates = 30
        record.protein = 10
        record.fat = 4
        record.createdAt = Date()
        record.mealTypeRawValue = MealType.snack.rawValue
        record.inputMethodRawValue = InputMethod.manual.rawValue
        return record
    }
}
