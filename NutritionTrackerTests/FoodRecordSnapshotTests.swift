import CoreData
import XCTest
@testable import NutritionTracker

final class FoodRecordSnapshotTests: XCTestCase {
    func testSnapshotPreservesEveryPersistedField() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let date = Date(timeIntervalSince1970: 1_768_478_400)
        let record = try FoodRecordStore().save(
            foodName: "鸡蛋（全蛋，生鲜）",
            mealType: .lunch,
            inputMethod: .photo,
            quantity: 2,
            portionName: "个（大号）",
            baseAmount: 100,
            baseUnit: .gram,
            catalogFoodID: "egg-chicken-whole",
            nutrition: PartialNutritionValues(
                calories: 143,
                carbohydrates: nil,
                protein: 12.6,
                fat: 9.5
            ),
            date: date,
            context: context
        )

        let snapshot = FoodRecordSnapshot(record: record)

        XCTAssertEqual(snapshot.id, record.id)
        XCTAssertEqual(snapshot.foodName, "鸡蛋（全蛋，生鲜）")
        XCTAssertEqual(snapshot.catalogFoodID, "egg-chicken-whole")
        XCTAssertEqual(snapshot.mealType, .lunch)
        XCTAssertEqual(snapshot.inputMethod, .photo)
        XCTAssertEqual(snapshot.quantity, 2)
        XCTAssertEqual(snapshot.portionName, "个（大号）")
        XCTAssertEqual(snapshot.baseAmount, 100)
        XCTAssertEqual(snapshot.baseUnit, .gram)
        XCTAssertEqual(
            snapshot.nutrition,
            PartialNutritionValues(
                calories: 143,
                carbohydrates: nil,
                protein: 12.6,
                fat: 9.5
            )
        )
        XCTAssertEqual(snapshot.createdAt, date)
    }
}
