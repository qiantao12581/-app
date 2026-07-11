import SwiftUI

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss

    let database: FoodDatabaseService
    let onSelect: (FoodReference) -> Void

    @State private var query = ""

    var body: some View {
        NavigationStack {
            List(database.search(query)) { food in
                Button {
                    onSelect(food)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(food.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(
                            "每100克：\(NutritionFormatters.oneDecimal(food.caloriesPer100Grams)) 千卡 · 碳水 \(NutritionFormatters.oneDecimal(food.carbohydratesPer100Grams)) 克 · 蛋白质 \(NutritionFormatters.oneDecimal(food.proteinPer100Grams)) 克 · 脂肪 \(NutritionFormatters.oneDecimal(food.fatPer100Grams)) 克"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("选择食物")
            .searchable(text: $query, prompt: "搜索名称或别名")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}
