import Foundation
import XCTest
@testable import NutritionTracker

final class FoodCatalogAuditTests: XCTestCase {
    func testReleaseCatalogHasExactly150ReviewedFoods() throws {
        let report = try FoodCatalogAuditor().audit(loadReleaseFoods())

        XCTAssertEqual(report.foodCount, 150)
        XCTAssertTrue(report.errors.isEmpty, report.errors.joined(separator: "\n"))
    }

    func testBrandedFoodsHaveTraceableOfficialSources() throws {
        let branded = try loadReleaseFoods().filter { $0.brandName != nil }

        XCTAssertTrue(branded.allSatisfy {
            !$0.source.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.source.url != nil
                && !$0.source.specification
                    .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.source.verifiedAt > Date(timeIntervalSince1970: 0)
        })
    }

    func testEveryFoodHasOneDefaultPortionAndDisplayMetadata() throws {
        let foods = try loadReleaseFoods()

        XCTAssertTrue(foods.allSatisfy { food in
            food.portions.filter(\.isDefault).count == 1
                && !food.display.iconKey
                    .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !food.display.colorKey
                    .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        })
    }

    private func loadReleaseFoods() throws -> [FoodReference] {
        let repository = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = repository
            .appendingPathComponent("NutritionTracker")
            .appendingPathComponent("Resources")
            .appendingPathComponent("foods.json")
        return try FoodDatabaseService(data: Data(contentsOf: url)).foods
    }
}
