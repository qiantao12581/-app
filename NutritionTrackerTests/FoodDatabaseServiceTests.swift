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

    func testSearchRanksExactPrefixAliasAndGenericFoodsDeterministically() throws {
        let service = try FoodDatabaseService(data: rankedSearchJSON)

        XCTAssertEqual(
            service.search("饺子").map(\.id),
            [
                "generic-dumpling",
                "generic-alias-dumpling",
                "generic-prefix-dumpling",
                "brand-prefix-dumpling",
                "generic-contained-dumpling",
                "brand-tag-dumpling"
            ]
        )
    }

    func testSearchNormalizesWidthCaseWhitespacePunctuationAndDiacritics() throws {
        let service = try FoodDatabaseService(data: rankedSearchJSON)

        XCTAssertEqual(service.search(" ＣＡＦÉ-牛 奶 ").first?.id, "normalized-milk")
        XCTAssertEqual(
            service.search("。。。").map(\.id),
            service.foods.map(\.id)
        )
    }

    func testDumplingSearchPrioritizesGenericBroadChoices() throws {
        let service = try releaseService()
        let ids = Array(service.search("饺子").prefix(3).map(\.id))

        XCTAssertEqual(ids.first, "generic-meat-dumpling")
        XCTAssertEqual(
            Set(ids.dropFirst()),
            Set([
                "generic-vegetarian-dumpling",
                "generic-pan-fried-dumpling"
            ])
        )
    }

    func testExactBrandNameRanksAheadWhenUserTypesBrand() throws {
        let service = try releaseService()

        XCTAssertEqual(
            service.search("三全芹菜猪肉水饺").first?.id,
            "sanquan-celery-pork-dumpling"
        )
    }

    func testRejectsInvalidSuggestedRange() {
        let invalidJSON = """
        [{"id":"bad","name":"错误食物","aliases":[],"category":"staple","suitableMeals":["lunch"],"caloriesPer100Grams":1,"carbohydratesPer100Grams":1,"proteinPer100Grams":1,"fatPer100Grams":1,"minimumSuggestedGrams":200,"maximumSuggestedGrams":100,"suggestionStepGrams":25}]
        """.data(using: .utf8)!

        XCTAssertThrowsError(try FoodDatabaseService(data: invalidJSON)) { error in
            XCTAssertEqual(error as? FoodDatabaseError, .invalidFoodData("错误食物"))
        }
    }

    private var rankedSearchJSON: Data {
        let rows = [
            rankedFood(id: "brand-prefix-dumpling", name: "饺子王水饺", brand: "饺子王"),
            rankedFood(id: "generic-contained-dumpling", name: "家常饺子拼盘"),
            rankedFood(id: "generic-prefix-dumpling", name: "饺子拼盘"),
            rankedFood(id: "generic-alias-dumpling", name: "肉馅水饺", aliases: ["饺子"]),
            rankedFood(id: "generic-dumpling", name: "饺子"),
            rankedFood(id: "brand-tag-dumpling", name: "速冻面点", brand: "三全", tags: ["饺子"]),
            rankedFood(id: "normalized-milk", name: "Cafe牛奶")
        ]
        return try! JSONSerialization.data(withJSONObject: rows)
    }

    private func rankedFood(
        id: String,
        name: String,
        aliases: [String] = [],
        brand: String? = nil,
        tags: [String] = []
    ) -> [String: Any] {
        var row: [String: Any] = [
            "id": id,
            "name": name,
            "aliases": aliases,
            "category": "staple",
            "suitableMeals": ["lunch"],
            "nutrition": [
                "calories": 200.0,
                "carbohydrates": 25.0,
                "protein": 8.0,
                "fat": 7.0
            ],
            "nutritionBasisAmount": 100.0,
            "nutritionBasisUnit": "gram",
            "portions": [[
                "id": "gram",
                "name": "克",
                "baseAmount": 1.0,
                "baseUnit": "gram",
                "allowsDecimalQuantity": true,
                "isDefault": true
            ]],
            "source": [
                "type": "chinaFoodComposition",
                "name": "测试来源",
                "url": NSNull(),
                "verifiedAt": "2026-07-14T00:00:00Z",
                "specification": "每100克"
            ],
            "display": [
                "iconKey": "fork.knife",
                "colorKey": "orange",
                "tags": tags
            ],
            "dataCompleteness": "complete",
            "minimumSuggestedGrams": 50.0,
            "maximumSuggestedGrams": 300.0,
            "suggestionStepGrams": 25.0
        ]
        if let brand { row["brandName"] = brand }
        return row
    }

    private func releaseService() throws -> FoodDatabaseService {
        try FoodDatabaseService(
            data: Data(contentsOf: releaseCatalogURL)
        )
    }

    private var releaseCatalogURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("NutritionTracker")
            .appendingPathComponent("Resources")
            .appendingPathComponent("foods.json")
    }
}
