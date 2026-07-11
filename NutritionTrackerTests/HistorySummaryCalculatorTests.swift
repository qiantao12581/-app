import XCTest
@testable import NutritionTracker

final class HistorySummaryCalculatorTests: XCTestCase {
    func testGroupsByDayNewestFirstAndTotalsNutrition() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let firstDay = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 10, hour: 8))
        )
        let firstDayLater = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 10, hour: 18))
        )
        let secondDay = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 11, hour: 12))
        )

        let summaries = HistorySummaryCalculator.summaries(
            entries: [
                DatedNutritionValues(
                    date: firstDay,
                    nutrition: NutritionValues(
                        calories: 100,
                        carbohydrates: 10,
                        protein: 5,
                        fat: 2
                    )
                ),
                DatedNutritionValues(
                    date: firstDayLater,
                    nutrition: NutritionValues(
                        calories: 200,
                        carbohydrates: 20,
                        protein: 15,
                        fat: 8
                    )
                ),
                DatedNutritionValues(
                    date: secondDay,
                    nutrition: NutritionValues(
                        calories: 350,
                        carbohydrates: 40,
                        protein: 25,
                        fat: 10
                    )
                )
            ],
            calendar: calendar
        )

        XCTAssertEqual(summaries.count, 2)
        XCTAssertEqual(summaries[0].date, calendar.startOfDay(for: secondDay))
        XCTAssertEqual(summaries[0].nutrition.calories, 350)
        XCTAssertEqual(summaries[1].date, calendar.startOfDay(for: firstDay))
        XCTAssertEqual(summaries[1].nutrition.calories, 300)
        XCTAssertEqual(summaries[1].nutrition.carbohydrates, 30)
        XCTAssertEqual(summaries[1].nutrition.protein, 20)
        XCTAssertEqual(summaries[1].nutrition.fat, 10)
    }

    func testEmptyEntriesReturnNoSummaries() {
        XCTAssertTrue(HistorySummaryCalculator.summaries(entries: []).isEmpty)
    }
}
