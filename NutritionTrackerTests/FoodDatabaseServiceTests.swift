import Foundation
import XCTest
@testable import NutritionTracker

final class FoodDatabaseServiceTests: XCTestCase {
    private let validJSON = """
    [
      {
        "id": "rice-cooked",
        "name": "熟米饭",
        "aliases": ["米饭", "白饭"],
        "category": "staple",
        "suitableMeals": ["lunch", "dinner"],
        "caloriesPer100Grams": 116,
        "carbohydratesPer100Grams": 25.9,
        "proteinPer100Grams": 2.6,
        "fatPer100Grams": 0.3,
        "minimumSuggestedGrams": 50,
        "maximumSuggestedGrams": 300,
        "suggestionStepGrams": 25
      },
      {
        "id": "egg-boiled",
        "name": "鸡蛋",
        "aliases": ["水煮蛋", "egg"],
        "category": "protein",
        "suitableMeals": ["breakfast", "snack"],
        "caloriesPer100Grams": 144,
        "carbohydratesPer100Grams": 0.8,
        "proteinPer100Grams": 13.3,
        "fatPer100Grams": 9.5,
        "minimumSuggestedGrams": 50,
        "maximumSuggestedGrams": 150,
        "suggestionStepGrams": 50
      }
    ]
    """.data(using: .utf8)!

    func testDecodesFoodAndBuildsPer100Nutrition() throws {
        let service = try FoodDatabaseService(data: validJSON)

        XCTAssertEqual(service.foods.count, 2)
        XCTAssertEqual(service.foods[0].name, "熟米饭")
        XCTAssertEqual(service.foods[0].nutritionPer100Grams?.carbohydrates, 25.9)
        XCTAssertEqual(service.foods[1].category, .protein)
    }

    func testSearchesNameAndAliasesCaseInsensitively() throws {
        let service = try FoodDatabaseService(data: validJSON)

        XCTAssertEqual(service.search("熟米").map(\.id), ["rice-cooked"])
        XCTAssertEqual(service.search("白饭").map(\.id), ["rice-cooked"])
        XCTAssertEqual(service.search("EGG").map(\.id), ["egg-boiled"])
    }

    func testBlankSearchReturnsAllFoods() throws {
        let service = try FoodDatabaseService(data: validJSON)

        XCTAssertEqual(service.search("   ").map(\.id), ["rice-cooked", "egg-boiled"])
    }

    func testRejectsInvalidSuggestedRange() {
        let invalidJSON = """
        [{"id":"bad","name":"错误食物","aliases":[],"category":"staple","suitableMeals":["lunch"],"caloriesPer100Grams":1,"carbohydratesPer100Grams":1,"proteinPer100Grams":1,"fatPer100Grams":1,"minimumSuggestedGrams":200,"maximumSuggestedGrams":100,"suggestionStepGrams":25}]
        """.data(using: .utf8)!

        XCTAssertThrowsError(try FoodDatabaseService(data: invalidJSON)) { error in
            XCTAssertEqual(error as? FoodDatabaseError, .invalidFoodData("错误食物"))
        }
    }
}
