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
}
