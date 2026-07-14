import Foundation
import XCTest
@testable import NutritionTracker

final class FoodCatalogAuditTests: XCTestCase {
    func testReleaseCatalogHasExactly500CompleteFoods() throws {
        let foods = try loadReleaseFoods()
        let report = try FoodCatalogAuditor(expectedCount: 500).audit(foods)

        XCTAssertEqual(report.foodCount, 500)
        XCTAssertTrue(report.errors.isEmpty, report.errors.joined(separator: "\n"))
        XCTAssertTrue(foods.allSatisfy { $0.completeNutrition != nil })
    }

    func testEveryFoodHasTraceableSourceMetadata() throws {
        let foods = try loadReleaseFoods()

        XCTAssertTrue(foods.allSatisfy {
            !$0.source.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && ($0.source.type == .recipeEstimate || $0.source.url != nil)
                && !$0.source.specification
                    .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.source.verifiedAt > Date(timeIntervalSince1970: 0)
        })
    }

    func testEveryReleaseFoodHasExplicitEvidenceLevel() throws {
        let foods = try loadReleaseFoods()
        let data = try Data(contentsOf: releaseCatalogURL)
        let objects = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        )

        XCTAssertEqual(foods.count, objects.count)
        XCTAssertTrue(objects.allSatisfy { row in
            let source = row["source"] as? [String: Any]
            return source?["evidenceLevel"] as? String == "official"
                || source?["evidenceLevel"] as? String == "nonOfficial"
        })
    }

    func testReleaseManifestExactlyMatchesCatalog() throws {
        let foods = try loadReleaseFoods()
        let markdown = try String(
            contentsOf: repositoryURL
                .appendingPathComponent("docs")
                .appendingPathComponent("data")
                .appendingPathComponent("food-catalog-sources.md"),
            encoding: .utf8
        )

        XCTAssertEqual(
            FoodCatalogManifestChecker.audit(
                markdown: markdown,
                foods: foods,
                expectedCount: 500
            ),
            []
        )
    }

    func testManifestCheckerReportsMissingDuplicateAndMismatchedRows() throws {
        let foods = Array(try loadReleaseFoods().prefix(2))
        let firstRow = FoodCatalogManifestChecker.markdownRow(for: foods[0])
        let secondRow = FoodCatalogManifestChecker.markdownRow(for: foods[1])

        let missing = FoodCatalogManifestChecker.audit(
            markdown: manifest(rows: [firstRow]),
            foods: foods,
            expectedCount: 2
        )
        XCTAssertTrue(missing.contains("manifest.count expected=2 actual=1"))
        XCTAssertTrue(missing.contains("manifest.missingID id=\(foods[1].id)"))

        let duplicate = FoodCatalogManifestChecker.audit(
            markdown: manifest(rows: [firstRow, firstRow]),
            foods: [foods[0]],
            expectedCount: 1
        )
        XCTAssertTrue(duplicate.contains("manifest.duplicateID id=\(foods[0].id) count=2"))

        let mismatchedRow = secondRow.replacingOccurrences(
            of: "| \(foods[1].name) |",
            with: "| 错误名称 |"
        )
        let mismatched = FoodCatalogManifestChecker.audit(
            markdown: manifest(rows: [firstRow, mismatchedRow]),
            foods: foods,
            expectedCount: 2
        )
        XCTAssertTrue(mismatched.contains(
            "manifest.fieldMismatch id=\(foods[1].id) field=name"
        ))
    }

    func testReleaseSourceDatesUseStrictUTCISO8601Strings() throws {
        let data = try Data(contentsOf: releaseCatalogURL)

        XCTAssertEqual(try RawFoodCatalogChecker.verifiedAtErrors(data: data), [])
    }

    func testRawSourceDateCheckerRejectsOffsetTimestamp() throws {
        let data = Data(
            #"[{"id":"offset","source":{"verifiedAt":"2026-07-12T08:00:00+08:00"}}]"#
                .utf8
        )

        XCTAssertEqual(
            try RawFoodCatalogChecker.verifiedAtErrors(data: data),
            ["food.invalidVerifiedAtFormat id=offset"]
        )
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

    func testReleaseEggHasDefaultGramAndPieceAlternative() throws {
        let egg = try XCTUnwrap(
            loadReleaseFoods().first(where: { $0.id == "egg-chicken-whole" })
        )
        let piece = try XCTUnwrap(egg.portions.first(where: { $0.id == "large-egg" }))
        let gram = try XCTUnwrap(egg.portions.first(where: { $0.id == "gram" }))

        XCTAssertEqual(piece.name, "个（大号）")
        XCTAssertEqual(piece.baseAmount, 50)
        XCTAssertEqual(piece.baseUnit, .gram)
        XCTAssertFalse(piece.allowsDecimalQuantity)
        XCTAssertFalse(piece.isDefault)
        XCTAssertEqual(gram.name, "克")
        XCTAssertEqual(gram.baseAmount, 1)
        XCTAssertEqual(gram.baseUnit, .gram)
        XCTAssertTrue(gram.allowsDecimalQuantity)
        XCTAssertTrue(gram.isDefault)
    }

    func testEveryReleaseMilliliterFoodHasExactOneMilliliterAlternative() throws {
        let milliliterFoods = try loadReleaseFoods().filter {
            $0.nutritionBasisUnit == .milliliter
        }

        XCTAssertFalse(milliliterFoods.isEmpty)
        for food in milliliterFoods {
            let portion = try XCTUnwrap(
                food.portions.first(where: { $0.id == "milliliter" }),
                "Missing 1mL alternative for \(food.id)"
            )
            XCTAssertEqual(portion.name, "毫升", food.id)
            XCTAssertEqual(portion.baseAmount, 1, food.id)
            XCTAssertEqual(portion.baseUnit, .milliliter, food.id)
            XCTAssertTrue(portion.allowsDecimalQuantity, food.id)
            XCTAssertFalse(portion.isDefault, food.id)
            XCTAssertNotEqual(food.defaultPortion?.id, portion.id, food.id)
        }
    }

    func testReleaseTelunsuCartonSwitchPreservesAmountAndNutrition() throws {
        let food = try XCTUnwrap(
            loadReleaseFoods().first(where: { $0.id == "mengniu-telunsu-pure-36" })
        )
        var selection = FoodQuantitySelection(food: food)
        let cartonNutrition = try XCTUnwrap(selection.actualNutrition)

        XCTAssertEqual(selection.selectedPortionID, "carton-250")
        XCTAssertEqual(selection.convertedBaseAmount, 250)
        XCTAssertEqual(selection.baseUnit, .milliliter)

        selection.selectPortion(id: "milliliter")

        XCTAssertEqual(selection.selectedPortionID, "milliliter")
        XCTAssertEqual(selection.quantityValue, 250)
        XCTAssertEqual(selection.convertedBaseAmount, 250)
        XCTAssertEqual(selection.baseUnit, .milliliter)
        XCTAssertEqual(selection.actualNutrition, cartonNutrition)
    }

    private func loadReleaseFoods() throws -> [FoodReference] {
        try FoodDatabaseService(data: Data(contentsOf: releaseCatalogURL)).foods
    }

    private var repositoryURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var releaseCatalogURL: URL {
        repositoryURL
            .appendingPathComponent("NutritionTracker")
            .appendingPathComponent("Resources")
            .appendingPathComponent("foods.json")
    }

    private func manifest(rows: [String]) -> String {
        ([
            "| ID | Chinese name | Brand | Specification | Source type | Evidence | URL | Verified at | Completeness | Catalog category |",
            "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"
        ] + rows).joined(separator: "\n")
    }
}

private enum FoodCatalogManifestChecker {
    private struct Row {
        let fields: [String]

        var id: String { fields[0] }
    }

    static func audit(
        markdown: String,
        foods: [FoodReference],
        expectedCount: Int
    ) -> [String] {
        var errors: [String] = []
        let rows = parse(markdown: markdown, errors: &errors)

        if rows.count != expectedCount {
            errors.append("manifest.count expected=\(expectedCount) actual=\(rows.count)")
        }

        let rowsByID = Dictionary(grouping: rows, by: \.id)
        for id in rowsByID.keys.sorted() {
            guard let matches = rowsByID[id], matches.count > 1 else { continue }
            errors.append("manifest.duplicateID id=\(id) count=\(matches.count)")
        }

        let foodsByID = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })
        for food in foods.sorted(by: { $0.id < $1.id }) {
            guard let row = rowsByID[food.id]?.first else {
                errors.append("manifest.missingID id=\(food.id)")
                continue
            }
            let expected = expectedFields(for: food)
            for index in expected.indices where row.fields[index] != expected[index] {
                errors.append(
                    "manifest.fieldMismatch id=\(food.id) field=\(fieldNames[index])"
                )
            }
        }

        for id in rowsByID.keys.sorted() where foodsByID[id] == nil {
            errors.append("manifest.unknownID id=\(id)")
        }

        return errors
    }

    static func markdownRow(for food: FoodReference) -> String {
        "| " + expectedFields(for: food).enumerated().map { index, value in
            index == 6 && !value.isEmpty ? "<\(value)>" : value
        }.joined(separator: " | ") + " |"
    }

    private static func parse(markdown: String, errors: inout [String]) -> [Row] {
        var rows: [Row] = []
        for (lineIndex, line) in markdown.components(separatedBy: .newlines).enumerated() {
            guard line.hasPrefix("|") else { continue }
            let columns = line.split(
                separator: "|",
                omittingEmptySubsequences: false
            ).dropFirst().dropLast().map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard columns.first != "ID", columns.first != "---" else { continue }
            guard columns.count == fieldNames.count else {
                errors.append(
                    "manifest.invalidColumns line=\(lineIndex + 1) actual=\(columns.count)"
                )
                continue
            }
            var fields = columns
            fields[6] = fields[6].trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
            rows.append(Row(fields: fields))
        }
        return rows
    }

    private static func expectedFields(for food: FoodReference) -> [String] {
        [
            food.id,
            food.name,
            food.brandName ?? "—",
            food.source.specification,
            food.source.type.rawValue,
            food.source.evidenceLevel.rawValue,
            food.source.url?.absoluteString ?? "",
            utcString(food.source.verifiedAt),
            food.dataCompleteness.rawValue,
            food.category.rawValue
        ]
    }

    private static let fieldNames = [
        "id", "name", "brand", "specification", "sourceType", "evidence",
        "url", "verifiedAt", "completeness", "category"
    ]

    private static func utcString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.string(from: date)
    }
}

private enum RawFoodCatalogChecker {
    static func verifiedAtErrors(data: Data) throws -> [String] {
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return ["catalog.invalidRawJSON"]
        }

        return rows.compactMap { row in
            let id = row["id"] as? String ?? "<missing>"
            guard
                let source = row["source"] as? [String: Any],
                let value = source["verifiedAt"] as? String,
                isStrictUTC(value)
            else {
                return "food.invalidVerifiedAtFormat id=\(id)"
            }
            return nil
        }
    }

    private static func isStrictUTC(_ value: String) -> Bool {
        let pattern = #"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"#
        guard value.range(of: pattern, options: .regularExpression) != nil else {
            return false
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.isLenient = false
        guard let date = formatter.date(from: value) else { return false }
        return formatter.string(from: date) == value
    }
}

final class FoodCatalogAuditorRuleTests: XCTestCase {
    private let auditor = FoodCatalogAuditor(expectedCount: 1)

    func testReportsUnexpectedFoodCount() throws {
        XCTAssertEqual(
            try FoodCatalogAuditor(expectedCount: 2).audit([fixture()]).errors.first,
            "catalog.count expected=2 actual=1"
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

    func testReportsIncompleteSourceMetadataForGenericFood() throws {
        let source = FoodSourceMetadata(
            type: .packageLabel,
            name: " ",
            url: nil,
            verifiedAt: Date(timeIntervalSince1970: 0),
            specification: ""
        )

        let errors = try auditor.audit([
            fixture(source: source)
        ]).errors

        XCTAssertTrue(errors.contains("food.sourceMetadata id=fixture field=name"))
        XCTAssertTrue(errors.contains("food.sourceMetadata id=fixture field=url"))
        XCTAssertTrue(errors.contains("food.sourceMetadata id=fixture field=verifiedAt"))
        XCTAssertTrue(errors.contains("food.sourceMetadata id=fixture field=specification"))
    }

    func testRecipeEstimateAllowsNilURLAndRequiresNonOfficialEvidence() throws {
        let source = FoodSourceMetadata(
            type: .recipeEstimate,
            evidenceLevel: .nonOfficial,
            name: "标准配方估算",
            url: nil,
            verifiedAt: Date(timeIntervalSince1970: 1),
            specification: "每100克熟制成品"
        )

        let errors = try auditor.audit([fixture(source: source)]).errors
        XCTAssertFalse(errors.contains("food.sourceMetadata id=fixture field=url"))
        XCTAssertFalse(errors.contains("food.sourceEvidenceMismatch id=fixture"))
    }

    func testDirectSourceRequiresOfficialEvidence() throws {
        let source = FoodSourceMetadata(
            type: .packageLabel,
            evidenceLevel: .nonOfficial,
            name: "包装标签",
            url: URL(string: "https://img.mengniu.com.cn/Uploads/product.png"),
            verifiedAt: Date(timeIntervalSince1970: 1),
            specification: "每100毫升"
        )

        let errors = try auditor.audit([fixture(source: source)]).errors
        XCTAssertTrue(errors.contains("food.sourceEvidenceMismatch id=fixture"))
    }

    func testRejectsArbitrarySpoofedAndSourceTypeMismatchedHosts() throws {
        let sources: [(String, FoodSourceMetadata, String)] = [
            (
                "arbitrary",
                source(type: .officialMenu, url: "https://example.com/product"),
                "food.unsupportedSourceHost id=arbitrary type=officialMenu host=example.com"
            ),
            (
                "spoofed",
                source(type: .officialMenu, url: "https://evil-mcdonalds.com.cn/product"),
                "food.unsupportedSourceHost id=spoofed type=officialMenu host=evil-mcdonalds.com.cn"
            ),
            (
                "mismatch",
                source(type: .brandWebsite, url: "https://www.mcdonalds.com.cn/product"),
                "food.unsupportedSourceHost id=mismatch type=brandWebsite host=www.mcdonalds.com.cn"
            )
        ]

        for (id, metadata, expected) in sources {
            let errors = try auditor.audit([fixture(id: id, source: metadata)]).errors
            XCTAssertTrue(errors.contains(expected), errors.joined(separator: "\n"))
        }
    }

    func testAcceptsOnlyExplicitCurrentOfficialHostFamilies() throws {
        let approved: [(FoodSourceType, String)] = [
            (.chinaFoodComposition, "https://nlc.chinanutri.cn/fq/foodinfo/259.html"),
            (.brandWebsite, "https://www.yili.com/product/1155"),
            (.packageLabel, "https://img.mengniu.com.cn/Uploads/product.png"),
            (.officialMenu, "https://WWW.MCDONALDS.COM.CN/product/Big-Mac")
        ]

        for (index, item) in approved.enumerated() {
            let errors = try auditor.audit([
                fixture(
                    id: "approved-\(index)",
                    source: source(type: item.0, url: item.1)
                )
            ]).errors
            let sourceErrors = errors.filter {
                $0.contains("Source") || $0.contains("sourceMetadata")
            }
            XCTAssertTrue(sourceErrors.isEmpty, sourceErrors.joined(separator: "\n"))
        }
    }

    func testAcceptsExactGovernmentLaboratoryHostsAndRejectsSuffixSpoof() throws {
        for url in [
            "https://www.cfs.gov.hk/english/nutrient/foodsearch.html",
            "https://fdc.nal.usda.gov/fdc-app.html"
        ] {
            let errors = try auditor.audit([
                fixture(source: source(type: .governmentLaboratory, url: url))
            ]).errors
            XCTAssertFalse(
                errors.contains(where: { $0.contains("unsupportedSourceHost") }),
                errors.joined(separator: "\n")
            )
        }

        let spoofed = try auditor.audit([
            fixture(
                source: source(
                    type: .governmentLaboratory,
                    url: "https://fdc.nal.usda.gov.evil.example/food"
                )
            )
        ]).errors
        XCTAssertTrue(spoofed.contains(
            "food.unsupportedSourceHost id=fixture "
                + "type=governmentLaboratory host=fdc.nal.usda.gov.evil.example"
        ))
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
            ]).errors.contains("food.completenessMismatch id=fixture expected=complete")
        )
        XCTAssertTrue(
            try auditor.audit([
                fixture(dataCompleteness: .missingOfficialFields)
            ]).errors.contains("food.completenessMismatch id=fixture expected=complete")
        )
    }

    func testReportsNamedMultipleOfficialMenuPortions() throws {
        let portions = [
            FoodPortion(
                id: "regular",
                name: "常规",
                baseAmount: 1,
                baseUnit: .serving,
                allowsDecimalQuantity: false,
                isDefault: true
            ),
            FoodPortion(
                id: "upsized",
                name: "加大",
                baseAmount: 1,
                baseUnit: .serving,
                allowsDecimalQuantity: false,
                isDefault: false
            )
        ]

        let errors = try auditor.audit([
            fixture(
                brandName: "连锁品牌",
                nutritionBasisAmount: 1,
                nutritionBasisUnit: .serving,
                portions: portions,
                source: menuSource
            )
        ]).errors

        XCTAssertTrue(errors.contains(
            "food.officialMenuServing id=fixture reason=portionCount actual=2"
        ))
    }

    func testReportsMultipleOfficialMenuPortionsWithoutSizeKeywords() throws {
        let portions = [
            menuPortion(id: "one", name: "一份", isDefault: true),
            menuPortion(id: "another", name: "另一份", isDefault: false)
        ]

        let errors = try auditor.audit([
            fixture(
                brandName: "连锁品牌",
                nutritionBasisAmount: 1,
                nutritionBasisUnit: .serving,
                portions: portions,
                source: menuSource
            )
        ]).errors

        XCTAssertTrue(errors.contains(
            "food.officialMenuServing id=fixture reason=portionCount actual=2"
        ))
    }

    func testReportsScaledOfficialMenuRecommendationRange() throws {
        let errors = try auditor.audit([
            fixture(
                brandName: "连锁品牌",
                nutritionBasisAmount: 1,
                nutritionBasisUnit: .serving,
                portions: [menuPortion(id: "serving", name: "1份", isDefault: true)],
                source: menuSource,
                minimumSuggestedGrams: 1,
                maximumSuggestedGrams: 2,
                suggestionStepGrams: 1
            )
        ]).errors

        XCTAssertTrue(errors.contains(
            "food.officialMenuServing id=fixture reason=recommendationRange"
        ))
    }

    func testAcceptsOneFixedIntegerOnlyOfficialServing() throws {
        let errors = try auditor.audit([
            fixture(
                brandName: "麦当劳中国",
                nutritionBasisAmount: 1,
                nutritionBasisUnit: .serving,
                portions: [menuPortion(id: "serving", name: "1个", isDefault: true)],
                source: menuSource
            )
        ]).errors

        XCTAssertFalse(
            errors.contains(where: { $0.hasPrefix("food.officialMenuServing") }),
            errors.joined(separator: "\n")
        )
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
        dataCompleteness: FoodDataCompleteness = .complete,
        minimumSuggestedGrams: Double = 1,
        maximumSuggestedGrams: Double = 1,
        suggestionStepGrams: Double = 1
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
            dataCompleteness: dataCompleteness,
            minimumSuggestedGrams: minimumSuggestedGrams,
            maximumSuggestedGrams: maximumSuggestedGrams,
            suggestionStepGrams: suggestionStepGrams
        )
    }

    private var menuSource: FoodSourceMetadata {
        source(
            type: .officialMenu,
            url: "https://www.mcdonalds.com.cn/product/Big-Mac"
        )
    }

    private func source(type: FoodSourceType, url: String) -> FoodSourceMetadata {
        FoodSourceMetadata(
            type: type,
            name: "中国大陆官方来源",
            url: URL(string: url),
            verifiedAt: Date(timeIntervalSince1970: 1),
            specification: "官方规格"
        )
    }

    private func menuPortion(
        id: String,
        name: String,
        isDefault: Bool
    ) -> FoodPortion {
        FoodPortion(
            id: id,
            name: name,
            baseAmount: 1,
            baseUnit: .serving,
            allowsDecimalQuantity: false,
            isDefault: isDefault
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
