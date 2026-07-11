import CoreData
import XCTest
@testable import NutritionTracker

final class PersistenceControllerTests: XCTestCase {
    func testFoodRecordCanBeSavedFetchedAndDeleted() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let record = FoodRecord(context: context)
        record.id = UUID()
        record.foodName = "熟米饭"
        record.weightGrams = 150
        record.calories = 174
        record.carbohydrates = 38.85
        record.protein = 3.9
        record.fat = 0.45
        record.createdAt = Date()
        record.mealTypeRawValue = MealType.lunch.rawValue
        record.inputMethodRawValue = InputMethod.manual.rawValue

        try context.save()

        var fetched = try context.fetch(FoodRecord.fetchRequest())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].foodName, "熟米饭")
        XCTAssertEqual(fetched[0].nutritionValues.calories, 174)
        XCTAssertEqual(fetched[0].mealType, .lunch)
        XCTAssertEqual(fetched[0].inputMethod, .manual)

        context.delete(fetched[0])
        try context.save()
        fetched = try context.fetch(FoodRecord.fetchRequest())
        XCTAssertTrue(fetched.isEmpty)
    }

    func testModelContainsDailyGoalAndNutritionSettings() {
        let controller = PersistenceController(inMemory: true)
        let entities = controller.container.managedObjectModel.entitiesByName

        XCTAssertNotNil(entities["DailyNutritionGoal"])
        XCTAssertNotNil(entities["NutritionSettings"])
    }
}
