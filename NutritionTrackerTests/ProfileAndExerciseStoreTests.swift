import CoreData
import XCTest
@testable import NutritionTracker

final class ProfileAndExerciseStoreTests: XCTestCase {
    func testSavingProfileUpdatesSingleton() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let store = UserProfileStore()
        let birthDate = try XCTUnwrap(
            Calendar.current.date(byAdding: .year, value: -30, to: Date())
        )

        let first = try store.save(
            biologicalSex: .male,
            birthDate: birthDate,
            heightCentimeters: 180,
            activityLevel: .light,
            customActivityFactor: 0,
            usesManualBMR: false,
            manualBMR: 0,
            context: context
        )
        let second = try store.save(
            biologicalSex: .male,
            birthDate: birthDate,
            heightCentimeters: 181,
            activityLevel: .moderate,
            customActivityFactor: 1.5,
            usesManualBMR: false,
            manualBMR: 0,
            context: context
        )

        XCTAssertEqual(first.objectID, second.objectID)
        XCTAssertEqual(second.heightCentimeters, 181)
        XCTAssertEqual(second.resolvedActivityFactor, 1.5)
        XCTAssertEqual(try context.fetch(UserProfile.fetchRequest()).count, 1)
    }

    func testExerciseTotalsOnlyRequestedDay() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let calendar = Calendar.current
        let today = Date()
        let yesterday = try XCTUnwrap(
            calendar.date(byAdding: .day, value: -1, to: today)
        )
        let store = ExerciseRecordStore()

        _ = try store.save(
            name: "力量训练",
            activeCalories: 300,
            durationMinutes: 60,
            date: today,
            context: context
        )
        _ = try store.save(
            name: "走路",
            activeCalories: 120,
            durationMinutes: 30,
            date: today,
            context: context
        )
        _ = try store.save(
            name: "昨天运动",
            activeCalories: 500,
            durationMinutes: 45,
            date: yesterday,
            context: context
        )

        XCTAssertEqual(
            try store.totalActiveCalories(for: today, context: context),
            420
        )
        XCTAssertEqual(try store.records(for: today, context: context).count, 2)
    }

    func testInvalidExerciseShowsChineseError() {
        let controller = PersistenceController(inMemory: true)

        XCTAssertThrowsError(
            try ExerciseRecordStore().save(
                name: " ",
                activeCalories: -1,
                durationMinutes: 0,
                date: Date(),
                context: controller.container.viewContext
            )
        ) { error in
            XCTAssertEqual(error.localizedDescription, "请输入运动名称")
        }
    }
}
