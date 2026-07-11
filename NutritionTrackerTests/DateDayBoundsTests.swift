import XCTest
@testable import NutritionTracker

final class DateDayBoundsTests: XCTestCase {
    func testDayBoundsContainOnlyTheSelectedCalendarDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 8 * 60 * 60))
        let selected = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 11, hour: 12)
        ))
        let nextDay = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 12, hour: 0)
        ))

        let bounds = selected.dayBounds(calendar: calendar)

        XCTAssertTrue(bounds.contains(selected))
        XCTAssertFalse(bounds.contains(nextDay))
        XCTAssertEqual(bounds.lowerBound, calendar.startOfDay(for: selected))
        XCTAssertEqual(bounds.upperBound, nextDay)
    }
}
