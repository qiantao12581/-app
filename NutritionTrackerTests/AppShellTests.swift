import XCTest
@testable import NutritionTracker

final class AppShellTests: XCTestCase {
    func testTabsHaveStableChineseTitles() {
        XCTAssertEqual(AppTab.allCases.map(\.title), ["今日", "添加", "历史"])
    }

    func testTabsHaveDistinctSystemImages() {
        XCTAssertEqual(Set(AppTab.allCases.map(\.systemImage)).count, AppTab.allCases.count)
    }
}
