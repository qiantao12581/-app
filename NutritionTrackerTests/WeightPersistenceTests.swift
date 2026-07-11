import CoreData
import XCTest
@testable import NutritionTracker

final class WeightPersistenceTests: XCTestCase {
    func testLatestWeightEntryBecomesCurrentWeight() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let calendar = Calendar.current
        let today = Date()
        let yesterday = try XCTUnwrap(
            calendar.date(byAdding: .day, value: -1, to: today)
        )
        let store = WeightEntryStore()

        _ = try store.save(
            weightKilograms: 90,
            date: yesterday,
            context: context
        )
        _ = try store.save(
            weightKilograms: 89.4,
            date: today,
            context: context
        )

        XCTAssertEqual(
            try XCTUnwrap(store.currentWeight(context: context)),
            89.4,
            accuracy: 0.0001
        )
    }

    func testSavingAutomaticGoalProjectsDateAndDeactivatesOldGoal() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let startDate = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 11))
        )
        let store = WeightGoalStore(calendar: calendar)

        let first = try store.save(
            startWeightKilograms: 100,
            targetWeightKilograms: 90,
            startDate: startDate,
            monthlyLossRate: 0.05,
            targetDateMode: .automatic,
            manualTargetDate: nil,
            context: context
        )
        let second = try store.save(
            startWeightKilograms: 100,
            targetWeightKilograms: 92,
            startDate: startDate,
            monthlyLossRate: 0.04,
            targetDateMode: .automatic,
            manualTargetDate: nil,
            context: context
        )

        XCTAssertEqual(
            first.targetDate,
            try XCTUnwrap(calendar.date(byAdding: .day, value: 63, to: startDate))
        )
        XCTAssertFalse(first.isActive)
        XCTAssertTrue(second.isActive)
        XCTAssertEqual(try context.fetch(WeightGoal.fetchRequest()).count, 2)
        XCTAssertEqual(
            try WeightGoalStore(calendar: calendar).activeGoal(context: context)?.objectID,
            second.objectID
        )
    }

    func testRejectsMonthlyRateOutsideThreeToFivePercent() {
        let controller = PersistenceController(inMemory: true)

        XCTAssertThrowsError(
            try WeightGoalStore().save(
                startWeightKilograms: 100,
                targetWeightKilograms: 90,
                startDate: Date(),
                monthlyLossRate: 0.06,
                targetDateMode: .automatic,
                manualTargetDate: nil,
                context: controller.container.viewContext
            )
        ) { error in
            XCTAssertEqual(error.localizedDescription, "每月减重比例必须在 3% 到 5% 之间")
        }
    }
}
