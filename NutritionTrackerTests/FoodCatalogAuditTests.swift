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

final class FoodCatalogAuditorRuleTests: XCTestCase {
    private let auditor = FoodCatalogAuditor()

    func testReportsUnexpectedFoodCount() throws {
        XCTAssertEqual(
            try auditor.audit([fixture()]).errors.first,
            "catalog.count expected=150 actual=1"
        )
    }

    func testReportsDuplicateIDs() throws {
        let errors = try auditor.audit([fixture(), fixture()]).errors

        XCTAssertTrue(errors.contains("food.duplicateID id=fixture count=2"))
    }

    func testReportsDuplicateNormalizedIdentity() throws {
        let first = fixture(id: "one", name: "  Whole-Milk ", brandName: "Brand A")
        let second = fixture(id: "two", name: "whole milk", brandName: "brand a")

        let errors = try auditor.audit([first, second]).errors

        XCTAssertTrue(errors.contains("food.duplicateIdentity ids=one,two"))
    }

    func testReportsAliasAndNameSearchCollisions() throws {
        let first = fixture(id: "one", name: "牛奶", aliases: ["纯 牛奶"])
        let second = fixture(id: "two", name: "纯-牛奶")

        let errors = try auditor.audit([first, second]).errors

        XCTAssertTrue(errors.contains("food.searchCollision term=纯牛奶 ids=one,two"))
    }

    func testReportsNegativeAndNonFiniteKnownNutrients() throws {
        let food = fixture(
            nutrition: PartialNutritionValues(
                calories: -1,
                carbohydrates: .infinity,
                protein: 3,
                fat: 4
            )
        )

        let errors = try auditor.audit([food]).errors

        XCTAssertTrue(errors.contains("food.invalidNutrient id=fixture field=calories"))
        XCTAssertTrue(errors.contains("food.invalidNutrient id=fixture field=carbohydrates"))
    }

    func testReportsInvalidNutritionBasis() throws {
        let errors = try auditor.audit([fixture(nutritionBasisAmount: 0)]).errors

        XCTAssertTrue(errors.contains("food.invalidBasis id=fixture"))
    }

    func testReportsInvalidPortionAmountUnitAndContinuousDecimalPolicy() throws {
        let portions = [
            FoodPortion(
                id: "invalid-amount",
                name: "无效",
                baseAmount: -.infinity,
                baseUnit: .gram,
                allowsDecimalQuantity: true,
                isDefault: false
            ),
            FoodPortion(
                id: "wrong-unit",
                name: "毫升",
                baseAmount: 1,
                baseUnit: .milliliter,
                allowsDecimalQuantity: true,
                isDefault: false
            ),
            FoodPortion(
                id: "gram",
                name: "克",
                baseAmount: 1,
                baseUnit: .gram,
                allowsDecimalQuantity: false,
                isDefault: true
            )
        ]

        let errors = try auditor.audit([fixture(portions: portions)]).errors

        XCTAssertTrue(errors.contains(
            "food.invalidPortion id=fixture portion=invalid-amount reason=nonpositiveOrNonfiniteAmount"
        ))
        XCTAssertTrue(errors.contains(
            "food.invalidPortion id=fixture portion=wrong-unit reason=unitMismatch"
        ))
        XCTAssertTrue(errors.contains(
            "food.invalidPortion id=fixture portion=gram reason=continuousUnitDisallowsDecimal"
        ))
    }

    func testReportsDuplicatePortionIDsAndMissingPortionNames() throws {
        let portions = [
            FoodPortion(
                id: "piece",
                name: "",
                baseAmount: 50,
                baseUnit: .gram,
                allowsDecimalQuantity: false,
                isDefault: true
            ),
            FoodPortion(
                id: "piece",
                name: "个",
                baseAmount: 50,
                baseUnit: .gram,
                allowsDecimalQuantity: false,
                isDefault: false
            )
        ]

        let errors = try auditor.audit([fixture(portions: portions)]).errors

        XCTAssertTrue(errors.contains("food.duplicatePortionID id=fixture portion=piece"))
        XCTAssertTrue(errors.contains("food.invalidPortion id=fixture portion=piece reason=missingName"))
    }

    func testReportsZeroOrMultipleDefaultPortions() throws {
        let noDefault = [portion(id: "one", isDefault: false)]
        let twoDefaults = [
            portion(id: "one", isDefault: true),
            portion(id: "two", isDefault: true)
        ]

        XCTAssertTrue(
            try auditor.audit([fixture(portions: noDefault)]).errors
                .contains("food.defaultPortionCount id=fixture actual=0")
        )
        XCTAssertTrue(
            try auditor.audit([fixture(portions: twoDefaults)]).errors
                .contains("food.defaultPortionCount id=fixture actual=2")
        )
    }

    func testReportsMissingDisplayMetadata() throws {
        let errors = try auditor.audit([
            fixture(display: FoodDisplayMetadata(iconKey: " ", colorKey: "", tags: []))
        ]).errors

        XCTAssertTrue(errors.contains("food.missingDisplay id=fixture field=iconKey"))
        XCTAssertTrue(errors.contains("food.missingDisplay id=fixture field=colorKey"))
    }

    func testReportsIncompleteBrandedSourceMetadata() throws {
        let source = FoodSourceMetadata(
            type: .packageLabel,
            name: " ",
            url: nil,
            verifiedAt: Date(timeIntervalSince1970: 0),
            specification: ""
        )

        let errors = try auditor.audit([
            fixture(brandName: "品牌", source: source)
        ]).errors

        XCTAssertTrue(errors.contains("food.brandedSource id=fixture field=name"))
        XCTAssertTrue(errors.contains("food.brandedSource id=fixture field=url"))
        XCTAssertTrue(errors.contains("food.brandedSource id=fixture field=verifiedAt"))
        XCTAssertTrue(errors.contains("food.brandedSource id=fixture field=specification"))
    }

    func testReportsInvalidSourceURLAndUnsupportedReleaseSourceType() throws {
        let invalidURLSource = FoodSourceMetadata(
            type: .brandWebsite,
            name: "官网",
            url: URL(string: "ftp://example.com/product"),
            verifiedAt: Date(timeIntervalSince1970: 1),
            specification: "250毫升"
        )
        let userSource = FoodSourceMetadata(
            type: .userProvided,
            name: "用户",
            url: URL(string: "https://example.com/product"),
            verifiedAt: Date(timeIntervalSince1970: 1),
            specification: "1份"
        )

        XCTAssertTrue(
            try auditor.audit([fixture(source: invalidURLSource)]).errors
                .contains("food.invalidSourceURL id=fixture")
        )
        XCTAssertTrue(
            try auditor.audit([fixture(source: userSource)]).errors
                .contains("food.unsupportedSourceType id=fixture type=userProvided")
        )
    }

    func testReportsCompletenessMismatch() throws {
        let incompleteValues = PartialNutritionValues(
            calories: 1,
            carbohydrates: nil,
            protein: 3,
            fat: 4
        )

        XCTAssertTrue(
            try auditor.audit([
                fixture(nutrition: incompleteValues, dataCompleteness: .complete)
            ]).errors.contains("food.completenessMismatch id=fixture expected=missingOfficialFields")
        )
        XCTAssertTrue(
            try auditor.audit([
                fixture(dataCompleteness: .missingOfficialFields)
            ]).errors.contains("food.completenessMismatch id=fixture expected=complete")
        )
    }

    func testReportsLinearScalingAcrossOfficialMenuSizes() throws {
        let source = FoodSourceMetadata(
            type: .officialMenu,
            name: "中国大陆官方菜单",
            url: URL(string: "https://example.com/fries"),
            verifiedAt: Date(timeIntervalSince1970: 1),
            specification: "小份/中份"
        )
        let portions = [
            FoodPortion(
                id: "small",
                name: "小份",
                baseAmount: 1,
                baseUnit: .serving,
                allowsDecimalQuantity: false,
                isDefault: true
            ),
            FoodPortion(
                id: "medium",
                name: "中份",
                baseAmount: 1.5,
                baseUnit: .serving,
                allowsDecimalQuantity: false,
                isDefault: false
            )
        ]

        let errors = try auditor.audit([
            fixture(
                brandName: "连锁品牌",
                nutritionBasisUnit: .serving,
                portions: portions,
                source: source
            )
        ]).errors

        XCTAssertTrue(errors.contains("food.unsupportedMenuSizeScaling id=fixture"))
    }

    private func fixture(
        id: String = "fixture",
        name: String = "测试食物",
        aliases: [String] = [],
        nutrition: PartialNutritionValues = PartialNutritionValues(
            calories: 1,
            carbohydrates: 2,
            protein: 3,
            fat: 4
        ),
        brandName: String? = nil,
        nutritionBasisAmount: Double = 100,
        nutritionBasisUnit: FoodMeasurementUnit = .gram,
        portions: [FoodPortion]? = nil,
        source: FoodSourceMetadata? = nil,
        display: FoodDisplayMetadata = FoodDisplayMetadata(
            iconKey: "fork.knife",
            colorKey: "green",
            tags: []
        ),
        dataCompleteness: FoodDataCompleteness = .complete
    ) -> FoodReference {
        FoodReference(
            id: id,
            name: name,
            aliases: aliases,
            category: .staple,
            suitableMeals: [.breakfast],
            nutrition: nutrition,
            brandName: brandName,
            nutritionBasisAmount: nutritionBasisAmount,
            nutritionBasisUnit: nutritionBasisUnit,
            portions: portions ?? [
                FoodPortion(
                    id: nutritionBasisUnit.rawValue,
                    name: nutritionBasisUnit.rawValue,
                    baseAmount: nutritionBasisAmount,
                    baseUnit: nutritionBasisUnit,
                    allowsDecimalQuantity: true,
                    isDefault: true
                )
            ],
            source: source ?? FoodSourceMetadata(
                type: .chinaFoodComposition,
                name: "中国食物成分表",
                url: URL(string: "https://nlc.chinanutri.cn/fq/"),
                verifiedAt: Date(timeIntervalSince1970: 1),
                specification: "每100克可食部"
            ),
            display: display,
            dataCompleteness: dataCompleteness
        )
    }

    private func portion(id: String, isDefault: Bool) -> FoodPortion {
        FoodPortion(
            id: id,
            name: id,
            baseAmount: 50,
            baseUnit: .gram,
            allowsDecimalQuantity: false,
            isDefault: isDefault
        )
    }
}
