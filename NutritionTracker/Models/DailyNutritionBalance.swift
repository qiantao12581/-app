import Foundation

/// 分别计算三大营养素的剩余量；负数表示当天已经超出目标。
struct DailyNutritionBalance: Equatable, Sendable {
    let target: NutritionValues
    let consumed: NutritionValues

    var remaining: NutritionValues {
        NutritionValues(
            calories: target.calories - consumed.calories,
            carbohydrates: target.carbohydrates - consumed.carbohydrates,
            protein: target.protein - consumed.protein,
            fat: target.fat - consumed.fat
        )
    }
}
