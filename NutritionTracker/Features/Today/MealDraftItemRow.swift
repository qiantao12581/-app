import SwiftUI

struct MealDraftItemRow: View {
    let item: MealSuggestionDraftItem
    let onQuantityChange: (String) -> Void
    let onPortionChange: (String) -> Void
    let onReplace: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FoodThumbnailView(food: item.food)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                TextField(
                    "请输入数量",
                    text: Binding(
                        get: { item.quantityText },
                        set: onQuantityChange
                    )
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("\(item.food.name)数量")

                Picker(
                    "单位",
                    selection: Binding(
                        get: { item.selectedPortionID },
                        set: onPortionChange
                    )
                ) {
                    ForEach(item.food.portions) { portion in
                        Text(portion.name).tag(portion.id)
                    }
                }
                .pickerStyle(.menu)
            }

            if let calculation = item.calculation {
                Text(
                    "折合 \(NutritionFormatters.oneDecimal(calculation.baseAmount)) "
                        + unitName(calculation.baseUnit)
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                nutritionText(calculation.nutrition)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let message = item.validationMessage {
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack {
                Button(action: onReplace) {
                    Label("替换食物", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(role: .destructive, action: onRemove) {
                    Label("删除", systemImage: "trash")
                }
                .buttonStyle(.borderless)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onRemove) {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private func nutritionText(_ nutrition: PartialNutritionValues) -> Text {
        Text("热量 \(formatted(nutrition.calories, unit: "千卡")) · ")
            + Text("碳水 \(formatted(nutrition.carbohydrates, unit: "克")) · ")
            + Text("蛋白质 \(formatted(nutrition.protein, unit: "克")) · ")
            + Text("脂肪 \(formatted(nutrition.fat, unit: "克"))")
    }

    private func formatted(_ value: Double?, unit: String) -> String {
        guard let value else { return "暂无官方数据" }
        return "\(NutritionFormatters.oneDecimal(value)) \(unit)"
    }

    private func unitName(_ unit: FoodMeasurementUnit) -> String {
        switch unit {
        case .gram: return "克"
        case .milliliter: return "毫升"
        case .serving: return "份"
        }
    }
}
