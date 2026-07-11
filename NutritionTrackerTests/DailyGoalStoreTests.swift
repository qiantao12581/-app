import CoreData
import XCTest
@testable import NutritionTracker

final class DailyGoalStoreTests: XCTestCase {
    func testCreatesTodayGoalFromDefaults() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let settings = NutritionSettings(context: context)
        settings.id = UUID()
        settings.defaultCarbohydrates = 200
        settings.defaultProtein = 120
        settings.defaultFat = 60
        settings.updatedAt = Date()
        try context.save()

        let goal = try DailyGoalStore().goal(for: Date(), context: context)

        XCTAssertEqual(goal.carbohydrates, 200)
        XCTAssertEqual(goal.protein, 120)
        XCTAssertEqual(goal.fat, 60)
    }

    func testSavingNewDefaultsDoesNotChangePastGoal() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let calendar = Calendar.current
        let yesterday = try XCTUnwrap(
            calendar.date(byAdding: .day, value: -1, to: Date())
        )
        let store = DailyGoalStore()

        let past = try store.save(
            for: yesterday,
            carbohydrates: 180,
            protein: 100,
            fat: 55,
            updateDefaults: true,
            context: context
        )
        _ = try store.save(
            for: Date(),
            carbohydrates: 220,
            protein: 140,
            fat: 70,
            updateDefaults: true,
            context: context
        )

        XCTAssertEqual(past.carbohydrates, 180)
        XCTAssertEqual(past.protein, 100)
        XCTAssertEqual(past.fat, 55)

        let settings = try XCTUnwrap(
            context.fetch(NutritionSettings.fetchRequest()).first
        )
        XCTAssertEqual(settings.defaultCarbohydrates, 220)
        XCTAssertEqual(settings.defaultProtein, 140)
        XCTAssertEqual(settings.defaultFat, 70)
    }

    func testGoalWithoutDefaultsThrowsChineseError() {
        let controller = PersistenceController(inMemory: true)

        XCTAssertThrowsError(
            try DailyGoalStore().goal(
                for: Date(),
                context: controller.container.viewContext
            )
        ) { error in
            XCTAssertEqual(error as? DailyGoalError, .missingDefaults)
            XCTAssertEqual(error.localizedDescription, "请先设置每日营养目标")
        }
    }
}
