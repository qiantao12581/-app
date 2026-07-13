import SwiftUI

struct MealNutritionImpactCard: View {
    let mealNutrition: PartialNutritionValues
    let remainingAfterMeal: PartialNutritionValues
    let isCalculationAvailable: Bool
    let hasIncompleteNutrition: Bool

    var body: some View {
        Section("本餐与当天剩余") {
            if !isCalculationAvailable {
                Label(
                    "请先修正无效份量，才能计算整餐营养",
                    systemImage: "exclamationmark.circle.fill"
                )
                .foregroundStyle(.red)
            }

            impactRow(
                title: "热量",
                mealValue: mealNutrition.calories,
                remainingValue: remainingAfterMeal.calories,
                unit: "千卡"
            )
            impactRow(
                title: "碳水化合物",
                mealValue: mealNutrition.carbohydrates,
                remainingValue: remainingAfterMeal.carbohydrates,
                unit: "克"
            )
            impactRow(
                title: "蛋白质",
                mealValue: mealNutrition.protein,
                remainingValue: remainingAfterMeal.protein,
                unit: "克"
            )
            impactRow(
                title: "脂肪",
                mealValue: mealNutrition.fat,
                remainingValue: remainingAfterMeal.fat,
                unit: "克"
            )

            if hasIncompleteNutrition {
                Label(
                    "部分食物缺少官方营养数据；缺失项不会按 0 计算。",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.footnote)
                .foregroundStyle(.orange)
            }
        }
    }

    private func impactRow(
        title: String,
        mealValue: Double?,
        remainingValue: Double?,
        unit: String
    ) -> some View {
        LabeledContent {
            VStack(alignment: .trailing, spacing: 3) {
                Text(
                    isCalculationAvailable
                        ? MealNutritionImpactPresentation.amountText(
                            mealValue,
                            unit: unit
                        )
                        : "无法计算"
                )
                .foregroundStyle(.secondary)
                Text(
                    isCalculationAvailable
                        ? MealNutritionImpactPresentation.remainingText(
                            remainingValue,
                            unit: unit
                        )
                        : "无法计算"
                )
                .font(.caption)
                .foregroundStyle(remainingColor(remainingValue))
            }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text("本餐 / 吃完后")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func remainingColor(_ value: Double?) -> Color {
        guard isCalculationAvailable, let value else { return .orange }
        return value < 0 ? .red : .green
    }
}
