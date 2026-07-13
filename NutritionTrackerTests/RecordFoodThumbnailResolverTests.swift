import XCTest
@testable import NutritionTracker

final class RecordFoodThumbnailResolverTests: XCTestCase {
    func testResolvesBuiltInDisplayMetadataByCatalogID() {
        let food = fixture(
            id: "built-in",
            name: "目录名称",
            display: FoodDisplayMetadata(
                iconKey: "fish",
                colorKey: "blue",
                tags: ["高蛋白", "水产"]
            )
        )
        let resolver = RecordFoodThumbnailResolver(
            builtInFoods: [food],
            customFoods: []
        )

        let result = resolver.resolve(
            catalogFoodID: "built-in",
            storedFoodName: "保存的名称"
        )

        XCTAssertEqual(result.name, "保存的名称")
        XCTAssertEqual(result.display, food.display)
        XCTAssertEqual(result.resolution, .builtIn)
        XCTAssertEqual(result.accessibilityLabel, "保存的名称，高蛋白，水产")
    }

    func testResolvesCustomDisplayMetadataAndTagsByCatalogID() {
        let food = fixture(
            id: "custom-01234567-89ab-cdef-0123-456789abcdef",
            name: "自定义食物",
            display: FoodDisplayMetadata(
                iconKey: "leaf",
                colorKey: "green",
                tags: ["自定义"]
            )
        )
        let resolver = RecordFoodThumbnailResolver(
            builtInFoods: [],
            customFoods: [.available(food)]
        )

        let result = resolver.resolve(
            catalogFoodID: food.id,
            storedFoodName: food.name
        )

        XCTAssertEqual(result.display, food.display)
        XCTAssertEqual(result.resolution, .custom)
        XCTAssertEqual(result.accessibilityLabel, "自定义食物，自定义")
    }

    func testReturnsStableAccessibleFallbackForLegacyAndUnknownRecords() {
        let resolver = RecordFoodThumbnailResolver(builtInFoods: [], customFoods: [])

        let legacy = resolver.resolve(catalogFoodID: nil, storedFoodName: " 手动豆浆 ")
        let unknown = resolver.resolve(
            catalogFoodID: "deleted-food",
            storedFoodName: "已删除食物"
        )

        XCTAssertEqual(legacy.name, "手动豆浆")
        XCTAssertEqual(legacy.display, .recordFallback)
        XCTAssertEqual(legacy.resolution, .fallback(.legacyOrManual))
        XCTAssertEqual(legacy.accessibilityLabel, "手动豆浆，食物缩略图不可用")
        XCTAssertEqual(unknown.display, .recordFallback)
        XCTAssertEqual(unknown.resolution, .fallback(.missingCatalogFood))
        XCTAssertEqual(unknown.accessibilityLabel, "已删除食物，食物缩略图不可用")
    }

    func testCorruptCustomDataIsReportedThroughAccessibleFallback() {
        let catalogID = "custom-01234567-89ab-cdef-0123-456789abcdef"
        let resolver = RecordFoodThumbnailResolver(
            builtInFoods: [],
            customFoods: [
                .unreadable(
                    catalogFoodID: catalogID,
                    message: "自定义食物的份量数据无法读取"
                )
            ]
        )

        let result = resolver.resolve(
            catalogFoodID: catalogID,
            storedFoodName: "损坏的食物"
        )

        XCTAssertEqual(result.display, .recordFallback)
        XCTAssertEqual(
            result.resolution,
            .fallback(.unreadableCustomFood("自定义食物的份量数据无法读取"))
        )
        XCTAssertEqual(result.accessibilityLabel, "损坏的食物，自定义食物数据无法读取")
    }

    private func fixture(
        id: String,
        name: String,
        display: FoodDisplayMetadata
    ) -> FoodReference {
        FoodReference(
            id: id,
            name: name,
            aliases: [],
            category: .snack,
            suitableMeals: [.snack],
            nutrition: PartialNutritionValues(
                calories: 100,
                carbohydrates: 10,
                protein: 5,
                fat: 2
            ),
            nutritionBasisAmount: 100,
            nutritionBasisUnit: .gram,
            portions: [
                FoodPortion(
                    id: "gram",
                    name: "克",
                    baseAmount: 1,
                    baseUnit: .gram,
                    allowsDecimalQuantity: true,
                    isDefault: true
                )
            ],
            source: FoodSourceMetadata(
                type: .userProvided,
                name: "测试",
                url: nil,
                verifiedAt: Date(timeIntervalSince1970: 1),
                specification: "测试"
            ),
            display: display,
            dataCompleteness: .complete
        )
    }
}
