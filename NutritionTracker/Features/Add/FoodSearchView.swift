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
                            "每100克：\(formatted(food.caloriesPer100Grams, unit: "千卡")) · 碳水 \(formatted(food.carbohydratesPer100Grams, unit: "克")) · 蛋白质 \(formatted(food.proteinPer100Grams, unit: "克")) · 脂肪 \(formatted(food.fatPer100Grams, unit: "克"))"
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

    private func formatted(_ value: Double?, unit: String) -> String {
        guard let value else { return "暂无官方数据" }
        return "\(NutritionFormatters.oneDecimal(value)) \(unit)"
    }
}
