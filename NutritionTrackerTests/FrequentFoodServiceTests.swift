import Foundation
import XCTest
@testable import NutritionTracker

final class FrequentFoodServiceTests: XCTestCase {
    func testMealSpecificFoodsRankBeforeGlobalFallbackWithoutDuplicates() {
        let candidates = FrequentFoodService().candidates(
            from: [
                snapshot(food: "鸡蛋", catalogID: "egg", meal: .breakfast, daysAgo: 1),
                snapshot(food: "鸡蛋", catalogID: "egg", meal: .breakfast, daysAgo: 2),
                snapshot(food: "米饭", catalogID: "rice", meal: .lunch, daysAgo: 1),
                snapshot(food: "牛奶", catalogID: "milk", meal: .snack, daysAgo: 1)
            ],
            mealType: .breakfast,
            now: now,
            limit: 3,
            calendar: calendar
        )

        XCTAssertEqual(candidates.map(\.catalogFoodID), ["egg", "milk", "rice"])
        XCTAssertEqual(candidates.first?.useCount, 2)
        XCTAssertEqual(Set(candidates.map(\.id)).count, candidates.count)
    }

    func testMealPhasePrecedesMoreFrequentGlobalFoodAndFallbackUsesGlobalCount() {
        let records = [
            snapshot(food: "早餐鸡蛋", catalogID: "egg", meal: .breakfast, daysAgo: 2),
            snapshot(food: "午餐米饭", catalogID: "rice", meal: .lunch, daysAgo: 0),
            snapshot(food: "午餐米饭", catalogID: "rice", meal: .lunch, daysAgo: 1),
            snapshot(food: "晚餐米饭", catalogID: "rice", meal: .dinner, daysAgo: 2),
            snapshot(food: "晚餐米饭", catalogID: "rice", meal: .dinner, daysAgo: 3)
        ]

        let candidates = FrequentFoodService().candidates(
            from: records,
            mealType: .breakfast,
            now: now,
            limit: 2,
            calendar: calendar
        )

        XCTAssertEqual(candidates.map(\.catalogFoodID), ["egg", "rice"])
        XCTAssertEqual(candidates.map(\.useCount), [1, 4])
    }

    func testThirtyDayWindowExcludesOlderAndFutureRecords() {
        let candidates = FrequentFoodService().candidates(
            from: [
                snapshot(food: "鸡蛋", catalogID: "egg", meal: .breakfast, daysAgo: 29),
                snapshot(food: "旧食物", catalogID: "old", meal: .breakfast, daysAgo: 30),
                snapshot(food: "未来食物", catalogID: "future", meal: .breakfast, daysAgo: -1)
            ],
            mealType: .breakfast,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(candidates.map(\.catalogFoodID), ["egg"])
    }

    func testSameCountUsesLatestDateThenStableKey() {
        let candidates = FrequentFoodService().candidates(
            from: [
                snapshot(food: "较新", catalogID: "newer", meal: .lunch, daysAgo: 0),
                snapshot(food: "B", catalogID: "b", meal: .lunch, daysAgo: 1),
                snapshot(food: "A", catalogID: "a", meal: .lunch, daysAgo: 1)
            ],
            mealType: .lunch,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(
            candidates.map(\.id),
            ["catalog:newer", "catalog:a", "catalog:b"]
        )
    }

    func testManualStableKeyNormalizesNameAndPortion() {
        let first = snapshot(
            food: "  Café 米饭！ ",
            catalogID: nil,
            meal: .dinner,
            daysAgo: 1,
            portionName: " 100 克。 "
        )
        let second = snapshot(
            food: "cafe米饭",
            catalogID: nil,
            meal: .dinner,
            daysAgo: 2,
            portionName: "100克"
        )

        XCTAssertEqual(first.stableFoodKey, "manual|cafe米饭|gram|100克")
        XCTAssertEqual(first.stableFoodKey, second.stableFoodKey)

        let candidates = FrequentFoodService().candidates(
            from: [first, second],
            mealType: .dinner,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates.first?.useCount, 2)
        XCTAssertEqual(candidates.first?.lastRecord.id, first.id)
    }

    func testCatalogRecordMayHaveMissingNutrientWhenAtLeastOneIsValid() {
        let record = snapshot(
            food: "官方食物",
            catalogID: "official",
            meal: .breakfast,
            daysAgo: 0,
            nutrition: PartialNutritionValues(
                calories: 100,
                carbohydrates: nil,
                protein: nil,
                fat: nil
            )
        )

        XCTAssertTrue(record.isReusableForQuickAdd)
        XCTAssertEqual(
            FrequentFoodService().candidates(
                from: [record],
                mealType: .breakfast,
                now: now,
                calendar: calendar
            ).map(\.catalogFoodID),
            ["official"]
        )
    }

    func testManualRecordRequiresCompleteNutrition() {
        let record = snapshot(
            food: "手动食物",
            catalogID: nil,
            meal: .breakfast,
            daysAgo: 0,
            nutrition: PartialNutritionValues(
                calories: 100,
                carbohydrates: 10,
                protein: nil,
                fat: 3
            )
        )

        XCTAssertFalse(record.isReusableForQuickAdd)
        XCTAssertTrue(
            FrequentFoodService().candidates(
                from: [record],
                mealType: .breakfast,
                now: now,
                calendar: calendar
            ).isEmpty
        )
    }

    func testInvalidQuantityBaseAmountAndNutritionAreExcluded() {
        let records = [
            snapshot(food: "零数量", catalogID: "zero", meal: .snack, daysAgo: 0, quantity: 0),
            snapshot(
                food: "无穷数量",
                catalogID: "infinite-quantity",
                meal: .snack,
                daysAgo: 0,
                quantity: .infinity
            ),
            snapshot(
                food: "负基础量",
                catalogID: "negative-base",
                meal: .snack,
                daysAgo: 0,
                baseAmount: -100
            ),
            snapshot(
                food: "缺少营养",
                catalogID: "missing",
                meal: .snack,
                daysAgo: 0,
                nutrition: PartialNutritionValues(
                    calories: nil,
                    carbohydrates: nil,
                    protein: nil,
                    fat: nil
                )
            ),
            snapshot(
                food: "负营养",
                catalogID: "negative-nutrition",
                meal: .snack,
                daysAgo: 0,
                nutrition: PartialNutritionValues(
                    calories: 100,
                    carbohydrates: 10,
                    protein: -1,
                    fat: 3
                )
            ),
            snapshot(
                food: "无穷营养",
                catalogID: "infinite-nutrition",
                meal: .snack,
                daysAgo: 0,
                nutrition: PartialNutritionValues(
                    calories: .infinity,
                    carbohydrates: nil,
                    protein: nil,
                    fat: nil
                )
            )
        ]

        XCTAssertTrue(records.allSatisfy { !$0.isReusableForQuickAdd })
        XCTAssertTrue(
            FrequentFoodService().candidates(
                from: records,
                mealType: .snack,
                now: now,
                calendar: calendar
            ).isEmpty
        )
    }

    func testEmptyNameOrPortionIsNotReusable() {
        let records = [
            snapshot(food: "  ", catalogID: "blank-name", meal: .lunch, daysAgo: 0),
            snapshot(
                food: "空份量",
                catalogID: "blank-portion",
                meal: .lunch,
                daysAgo: 0,
                portionName: "  "
            )
        ]

        XCTAssertTrue(records.allSatisfy { !$0.isReusableForQuickAdd })
    }

    func testNonPositiveLimitReturnsEmptyArray() {
        let record = snapshot(
            food: "鸡蛋",
            catalogID: "egg",
            meal: .breakfast,
            daysAgo: 0
        )
        let service = FrequentFoodService()

        XCTAssertTrue(
            service.candidates(
                from: [record],
                mealType: .breakfast,
                now: now,
                limit: 0,
                calendar: calendar
            ).isEmpty
        )
        XCTAssertTrue(
            service.candidates(
                from: [record],
                mealType: .breakfast,
                now: now,
                limit: -1,
                calendar: calendar
            ).isEmpty
        )
    }

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private var now: Date {
        Date(timeIntervalSince1970: 1_768_478_400)
    }

    private func snapshot(
        food: String,
        catalogID: String?,
        meal: MealType,
        daysAgo: Int,
        quantity: Double = 1,
        portionName: String = "100克",
        baseAmount: Double = 100,
        nutrition: PartialNutritionValues = PartialNutritionValues(
            calories: 100,
            carbohydrates: 10,
            protein: 8,
            fat: 3
        )
    ) -> FoodRecordSnapshot {
        FoodRecordSnapshot(
            id: UUID(),
            foodName: food,
            catalogFoodID: catalogID,
            mealType: meal,
            inputMethod: .manual,
            quantity: quantity,
            portionName: portionName,
            baseAmount: baseAmount,
            baseUnit: .gram,
            nutrition: nutrition,
            createdAt: calendar.date(
                byAdding: .day,
                value: -daysAgo,
                to: now
            )!
        )
    }
}
