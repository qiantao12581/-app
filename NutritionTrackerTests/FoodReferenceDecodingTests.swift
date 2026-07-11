import Foundation
import XCTest
@testable import NutritionTracker

final class FoodReferenceDecodingTests: XCTestCase {
    private let officialMilkJSON = """
    [
      {
        "id": "milk-carton",
        "name": "纯牛奶",
        "aliases": ["牛奶"],
        "category": "dairy",
        "suitableMeals": ["breakfast", "snack"],
        "nutrition": {
          "calories": 70,
          "carbohydrates": 5,
          "protein": 3.6,
          "fat": 4.4
        },
        "brandName": "测试乳业",
        "nutritionBasisAmount": 100,
        "nutritionBasisUnit": "milliliter",
        "portions": [
          {
            "id": "carton-250",
            "name": "盒",
            "baseAmount": 250,
            "baseUnit": "milliliter",
            "allowsDecimalQuantity": true,
            "isDefault": true
          }
        ],
        "source": {
          "type": "packageLabel",
          "name": "测试乳业纯牛奶包装营养成分表",
          "url": "https://example.com/milk",
          "verifiedAt": "2026-07-11T00:00:00Z",
          "specification": "250毫升/盒"
        },
        "display": {
          "iconKey": "milk",
          "colorKey": "blue",
          "tags": ["测试乳业", "全脂"]
        },
        "dataCompleteness": "complete",
        "minimumSuggestedGrams": 100,
        "maximumSuggestedGrams": 300,
        "suggestionStepGrams": 50
      }
    ]
    """.data(using: .utf8)!

    private let legacyRiceJSON = """
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
    }
    """.data(using: .utf8)!

    func testDecodesOfficialMilliliterFood() throws {
        let food = try XCTUnwrap(FoodDatabaseService(data: officialMilkJSON).foods.first)

        XCTAssertEqual(food.nutritionBasisAmount, 100)
        XCTAssertEqual(food.nutritionBasisUnit, .milliliter)
        XCTAssertEqual(food.defaultPortion?.name, "盒")
        XCTAssertEqual(food.source.type, .packageLabel)
        XCTAssertEqual(food.source.verifiedAt.timeIntervalSince1970, 1_783_728_000)
        XCTAssertEqual(food.display.tags, ["测试乳业", "全脂"])
        XCTAssertEqual(food.dataCompleteness, .complete)
        XCTAssertTrue(food.nutrition.isComplete)
        XCTAssertEqual(food.completeNutrition?.protein, 3.6)
    }

    func testLegacyFoodGetsBackwardCompatibleDefaults() throws {
        let food = try JSONDecoder().decode(FoodReference.self, from: legacyRiceJSON)

        XCTAssertEqual(food.nutrition, PartialNutritionValues(
            calories: 116,
            carbohydrates: 25.9,
            protein: 2.6,
            fat: 0.3
        ))
        XCTAssertEqual(food.nutritionBasisAmount, 100)
        XCTAssertEqual(food.nutritionBasisUnit, .gram)
        XCTAssertEqual(food.portions.first?.name, "克")
        XCTAssertEqual(food.portions.first?.baseAmount, 1)
        XCTAssertEqual(food.defaultPortion?.id, "gram")
        XCTAssertEqual(food.completeNutrition?.carbohydrates, 25.9)
    }

    func testIncompleteOfficialNutritionStaysMissing() throws {
        let incomplete = String(data: officialMilkJSON, encoding: .utf8)!
            .replacingOccurrences(of: "\"protein\": 3.6", with: "\"protein\": null")
            .replacingOccurrences(of: "\"dataCompleteness\": \"complete\"", with: "\"dataCompleteness\": \"missingOfficialFields\"")

        let food = try XCTUnwrap(
            FoodDatabaseService(data: Data(incomplete.utf8)).foods.first
        )

        XCTAssertNil(food.nutrition.protein)
        XCTAssertNil(food.completeNutrition)
        XCTAssertNil(food.proteinPer100Grams)
        XCTAssertEqual(food.dataCompleteness, .missingOfficialFields)
    }

    func testSearchMatchesBrandNameAndDisplayTags() throws {
        let service = try FoodDatabaseService(data: officialMilkJSON)

        XCTAssertEqual(service.search("测试乳业").map(\.id), ["milk-carton"])
        XCTAssertEqual(service.search("全脂").map(\.id), ["milk-carton"])
    }

    func testBundledLegacyCatalogDecodesAllFoods() throws {
        let repository = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let catalogURL = repository
            .appendingPathComponent("NutritionTracker")
            .appendingPathComponent("Resources")
            .appendingPathComponent("foods.json")

        let foods = try FoodDatabaseService(
            data: Data(contentsOf: catalogURL)
        ).foods

        XCTAssertEqual(foods.count, 22)
        XCTAssertTrue(foods.allSatisfy { food in
            food.nutritionBasisAmount == 100
                && food.nutritionBasisUnit == .gram
                && food.defaultPortion?.name == "克"
                && food.completeNutrition != nil
        })
    }
}
