import XCTest
@testable import NutritionTracker

final class NutritionFormattersTests: XCTestCase {
    func testFormatsOneDecimalPlace() {
        XCTAssertEqual(NutritionFormatters.oneDecimal(38.85), "38.9")
        XCTAssertEqual(NutritionFormatters.oneDecimal(3), "3.0")
    }

    func testParsesDotAndCommaDecimals() {
        XCTAssertEqual(NutritionFormatters.decimal(from: " 12.5 "), 12.5)
        XCTAssertEqual(NutritionFormatters.decimal(from: "12,5"), 12.5)
    }

    func testReturnsNilForNonnumericInput() {
        XCTAssertNil(NutritionFormatters.decimal(from: "十二"))
    }
}
