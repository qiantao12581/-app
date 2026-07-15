import CoreData
import XCTest
@testable import NutritionTracker

final class FoodRecordStoreTests: XCTestCase {
    func testRecordsReturnsOnlyRequestedDayNewestFirst() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let calendar = Calendar.current
        let today = Date()
        let morning = try XCTUnwrap(
            calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today)
        )
        let noon = try XCTUnwrap(
            calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)
        )
        let yesterday = try XCTUnwrap(
            calendar.date(byAdding: .day, value: -1, to: morning)
        )

        makeRecord(name: "早餐", date: morning, context: context)
        makeRecord(name: "午餐", date: noon, context: context)
        makeRecord(name: "昨天", date: yesterday, context: context)
        try context.save()

        let records = try FoodRecordStore().records(for: today, context: context)

        XCTAssertEqual(records.map(\.foodName), ["午餐", "早餐"])
    }

    func testDeletePersistsRemoval() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let record = makeRecord(name: "错误记录", date: Date(), context: context)
        try context.save()

        try FoodRecordStore().delete(record, context: context)

        XCTAssertTrue(try context.fetch(FoodRecord.fetchRequest()).isEmpty)
    }

    func testStoredNutritionSnapshotIsUnchangedWhenCatalogValuesChange() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        _ = try FoodRecordStore().save(
            foodName: "快照食物",
            mealType: .lunch,
            inputMethod: .manual,
            quantity: 2,
            portionName: "份",
            baseAmount: 200,
            baseUnit: .gram,
            catalogFoodID: "snapshot-food",
            nutrition: PartialNutritionValues(
                calories: 240,
                carbohydrates: 30,
                protein: 12,
                fat: 8
            ),
            context: context
        )

        let changedCatalog = try FoodDatabaseService(
            data: catalogData(
                id: "snapshot-food",
                name: "快照食物",
                calories: 999,
                carbohydrates: 88,
                protein: 77,
                fat: 66
            )
        )
        XCTAssertEqual(changedCatalog.foods.first?.nutrition.calories, 999)

        context.reset()
        let record = try XCTUnwrap(
            context.fetch(FoodRecord.fetchRequest()).first
        )
        XCTAssertEqual(record.catalogFoodID, "snapshot-food")
        XCTAssertEqual(record.calories, 240)
        XCTAssertEqual(record.carbohydrates, 30)
        XCTAssertEqual(record.protein, 12)
        XCTAssertEqual(record.fat, 8)
    }

    func testQuickAddPayloadPersistsSelectedMealQuantityAndNutrition() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let food = FoodReference(
            id: "quick-rice",
            name: "熟米饭",
            aliases: [],
            category: .staple,
            suitableMeals: [.lunch, .dinner],
            caloriesPer100Grams: 116,
            carbohydratesPer100Grams: 25.9,
            proteinPer100Grams: 2.6,
            fatPer100Grams: 0.3,
            minimumSuggestedGrams: 50,
            maximumSuggestedGrams: 400,
            suggestionStepGrams: 25
        )
        var state = QuickFoodQuantityState(
            selection: .catalog(food: food, remembered: nil),
            mealType: .dinner
        )
        state.updateQuantity("180")
        try state.validate()

        let quantity = try XCTUnwrap(state.quantityValue)
        let portionName = try XCTUnwrap(state.portionName)
        let baseAmount = try XCTUnwrap(state.baseAmount)
        let baseUnit = try XCTUnwrap(state.baseUnit)
        let nutrition = try XCTUnwrap(state.nutrition)
        let record = try FoodRecordStore().save(
            foodName: state.food.name,
            mealType: state.mealType,
            inputMethod: .manual,
            quantity: quantity,
            portionName: portionName,
            baseAmount: baseAmount,
            baseUnit: baseUnit,
            catalogFoodID: state.catalogFoodIDForSave,
            nutrition: nutrition,
            context: context
        )

        XCTAssertEqual(record.mealType, .dinner)
        XCTAssertEqual(record.inputMethod, .manual)
        XCTAssertEqual(record.presentedQuantity, 180)
        XCTAssertEqual(record.presentedPortionName, "克")
        XCTAssertEqual(record.presentedBaseAmount, 180)
        XCTAssertEqual(record.baseUnit, .gram)
        XCTAssertEqual(record.catalogFoodID, "quick-rice")
        XCTAssertEqual(record.calories, 208.8, accuracy: 0.000_001)
        XCTAssertEqual(record.carbohydrates, 46.62, accuracy: 0.000_001)
        XCTAssertEqual(record.protein, 4.68, accuracy: 0.000_001)
        XCTAssertEqual(record.fat, 0.54, accuracy: 0.000_001)
    }

    @discardableResult
    private func makeRecord(
        name: String,
        date: Date,
        context: NSManagedObjectContext
    ) -> FoodRecord {
        let record = FoodRecord(context: context)
        record.id = UUID()
        record.foodName = name
        record.weightGrams = 100
        record.calories = 100
        record.carbohydrates = 10
        record.protein = 10
        record.fat = 3
        record.createdAt = date
        record.mealTypeRawValue = MealType.snack.rawValue
        record.inputMethodRawValue = InputMethod.manual.rawValue
        return record
    }

    private func catalogData(
        id: String,
        name: String,
        calories: Double,
        carbohydrates: Double,
        protein: Double,
        fat: Double
    ) -> Data {
        """
        [{
          "id":"\(id)",
          "name":"\(name)",
          "aliases":[],
          "category":"staple",
          "suitableMeals":["lunch"],
          "caloriesPer100Grams":\(calories),
          "carbohydratesPer100Grams":\(carbohydrates),
          "proteinPer100Grams":\(protein),
          "fatPer100Grams":\(fat),
          "minimumSuggestedGrams":50,
          "maximumSuggestedGrams":300,
          "suggestionStepGrams":25
        }]
        """.data(using: .utf8)!
    }
}
