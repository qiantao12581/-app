import Foundation

extension FoodRecordSnapshot {
    /// 把 Core Data 对象转换成不依赖上下文的值，供常吃食物排序安全使用。
    init(record: FoodRecord) {
        self.init(
            id: record.id,
            foodName: record.foodName,
            catalogFoodID: record.catalogFoodID,
            mealType: record.mealType,
            inputMethod: record.inputMethod,
            quantity: record.presentedQuantity,
            portionName: record.presentedPortionName,
            baseAmount: record.presentedBaseAmount,
            baseUnit: record.baseUnit,
            nutrition: record.partialNutritionValues,
            createdAt: record.createdAt
        )
    }
}
