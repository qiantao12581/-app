import SwiftUI

struct MealSuggestionCard: View {
    let suggestion: MealSuggestion
    let catalog: [FoodReference]
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(suggestion.mealType.title, systemImage: mealImage)
                        .font(.headline)
                        .foregroundStyle(.green)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                ForEach(suggestion.items) { item in
                    if let food = food(for: item) {
                        HStack(alignment: .top, spacing: 10) {
                            FoodThumbnailView(food: food)
                            Spacer(minLength: 8)
                            Text(quantityText(for: item, food: food))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        HStack {
                            Text(item.foodID)
                            Spacer()
                            Text("食物数据不可用")
                                .foregroundStyle(.red)
                        }
                        .font(.subheadline)
                    }
                }

                Text(
                    "预计：碳水 \(NutritionFormatters.oneDecimal(suggestion.nutrition.carbohydrates)) 克 · "
                        + "蛋白质 \(NutritionFormatters.oneDecimal(suggestion.nutrition.protein)) 克 · "
                        + "脂肪 \(NutritionFormatters.oneDecimal(suggestion.nutrition.fat)) 克"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Label("点击后可改份量、替换或增删食物", systemImage: "pencil")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("编辑\(suggestion.mealType.title)建议")
    }

    private var mealImage: String {
        suggestion.mealType == .snack
            ? "takeoutbag.and.cup.and.straw"
            : "fork.knife"
    }

    private func food(for item: MealSuggestionItem) -> FoodReference? {
        catalog.first { $0.id == item.foodID }
    }

    private func quantityText(
        for item: MealSuggestionItem,
        food: FoodReference
    ) -> String {
        let portion = food.portions.first { $0.id == item.portionID }
        return "\(NutritionFormatters.oneDecimal(item.quantity)) "
            + (portion?.name ?? "份")
    }
}
