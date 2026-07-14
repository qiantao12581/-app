import Foundation
import XCTest
@testable import NutritionTracker

final class FoodNutritionRowPresentationTests: XCTestCase {
    func testGramFoodPresentationContainsOnlyCompactNutritionFields() {
        let food = fixtureFood(
            name: "肉馅水饺",
            nutrition: PartialNutritionValues(
                calories: 245.7,
                carbohydrates: 26.6,
                protein: 8.8,
                fat: 12.3
            ),
            evidence: .nonOfficial
        )

        let value = FoodNutritionRowPresentation(food: food)

        XCTAssertEqual(value.name, "肉馅水饺")
        XCTAssertEqual(value.evidenceBadge, "非官方")
        XCTAssertEqual(value.basisAndCalories, "每100克 · 245.7千卡")
        XCTAssertEqual(
            value.macros,
            "碳水 26.6克 · 蛋白质 8.8克 · 脂肪 12.3克"
        )
        XCTAssertFalse(value.basisAndCalories.contains(food.source.name))
        XCTAssertFalse(value.macros.contains(food.source.specification))
    }

    func testServingFoodKeepsOfficialServingBasisAndBrand() {
        let food = fixtureFood(
            name: "巨无霸",
            brandName: "麦当劳中国",
            nutrition: PartialNutritionValues(
                calories: 512.9,
                carbohydrates: 42,
                protein: 27,
                fat: 26
            ),
            basisAmount: 1,
            basisUnit: .serving,
            evidence: .official
        )

        let value = FoodNutritionRowPresentation(food: food)

        XCTAssertEqual(value.brandName, "麦当劳中国")
        XCTAssertEqual(value.evidenceBadge, "官方")
        XCTAssertEqual(value.basisAndCalories, "每1份 · 512.9千卡")
    }

    func testLegacyPartialNutritionUsesReadableMissingValueText() {
        let food = fixtureFood(
            name: "旧版自定义食物",
            nutrition: PartialNutritionValues(
                calories: 120,
                carbohydrates: nil,
                protein: 5,
                fat: nil
            ),
            evidence: .nonOfficial
        )

        let value = FoodNutritionRowPresentation(food: food)

        XCTAssertEqual(value.basisAndCalories, "每100克 · 120.0千卡")
        XCTAssertEqual(
            value.macros,
            "碳水 暂无数据 · 蛋白质 5.0克 · 脂肪 暂无数据"
        )
        XCTAssertTrue(value.accessibilityLabel.contains("暂无数据"))
    }

    private func fixtureFood(
        name: String,
        brandName: String? = nil,
        nutrition: PartialNutritionValues,
        basisAmount: Double = 100,
        basisUnit: FoodMeasurementUnit = .gram,
        evidence: FoodEvidenceLevel
    ) -> FoodReference {
        FoodReference(
            id: "fixture-\(name)",
            name: name,
            aliases: [],
            category: .staple,
            suitableMeals: [.lunch],
            nutrition: nutrition,
            brandName: brandName,
            nutritionBasisAmount: basisAmount,
            nutritionBasisUnit: basisUnit,
            portions: [FoodPortion(
                id: "default",
                name: basisUnit.chineseName,
                baseAmount: basisAmount,
                baseUnit: basisUnit,
                allowsDecimalQuantity: true,
                isDefault: true
            )],
            source: FoodSourceMetadata(
                type: evidence == .official ? .officialMenu : .recipeEstimate,
                evidenceLevel: evidence,
                name: "测试数据来源",
                url: nil,
                verifiedAt: Date(timeIntervalSince1970: 0),
                specification: "测试营养基准"
            ),
            display: FoodDisplayMetadata(
                iconKey: "fork.knife",
                colorKey: "orange",
                tags: []
            ),
            dataCompleteness: nutrition.isComplete ? .complete : .missingOfficialFields
        )
    }
}
