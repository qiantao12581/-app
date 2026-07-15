import Foundation
import XCTest
@testable import NutritionTracker

final class AppShellTests: XCTestCase {
    func testTabsHaveStableChineseTitles() {
        XCTAssertEqual(AppTab.allCases.map(\.title), ["今日", "添加", "历史"])
    }

    func testTabsHaveDistinctSystemImages() {
        XCTAssertEqual(Set(AppTab.allCases.map(\.systemImage)).count, AppTab.allCases.count)
    }

    func testTodaySuggestionsRequireExplicitButtonInsteadOfAutomaticRefresh() throws {
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("NutritionTracker")
            .appendingPathComponent("Features")
            .appendingPathComponent("Today")
            .appendingPathComponent("TodayView.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        XCTAssertTrue(source.contains("生成后续餐次建议"))
        XCTAssertTrue(source.contains("generateMealSuggestions()"))
        XCTAssertFalse(source.contains("refreshMealSuggestions()"))
    }
}
