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
                    VStack(alignment: .leading, spacing: 9) {
                        FoodThumbnailView(food: food)

                        metadataTags(for: food)

                        Label(sourceLabel(for: food), systemImage: "checkmark.seal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(nutritionBasisText(for: food))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("选择食物")
            .searchable(text: $query, prompt: "搜索名称、别名或品牌")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func metadataTags(for food: FoodReference) -> some View {
        let tags = [food.brandName, food.source.specification]
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else { return nil }
                return value
            }

        if !tags.isEmpty {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { metadataCapsule($0) }
                }
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(tags, id: \.self) { metadataCapsule($0) }
                }
            }
        }
    }

    private func metadataCapsule(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .lineLimit(2)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.secondary.opacity(0.12), in: Capsule())
    }

    private func sourceLabel(for food: FoodReference) -> String {
        "\(sourceTypeName(food.source.type)) · \(food.source.name)"
    }

    private func nutritionBasisText(for food: FoodReference) -> String {
        let amount = NutritionFormatters.oneDecimal(food.nutritionBasisAmount)
        let basis = "每 \(amount) \(unitName(food.nutritionBasisUnit))"
        return "\(basis)：热量 \(formatted(food.nutrition.calories, unit: "千卡")) · 碳水 \(formatted(food.nutrition.carbohydrates, unit: "克")) · 蛋白质 \(formatted(food.nutrition.protein, unit: "克")) · 脂肪 \(formatted(food.nutrition.fat, unit: "克"))"
    }

    private func formatted(_ value: Double?, unit: String) -> String {
        guard let value else { return "暂无官方数据" }
        return "\(NutritionFormatters.oneDecimal(value)) \(unit)"
    }

    private func sourceTypeName(_ type: FoodSourceType) -> String {
        switch type {
        case .chinaFoodComposition: return "中国食物成分"
        case .brandWebsite: return "品牌官网"
        case .packageLabel: return "官方包装"
        case .officialMenu: return "官方菜单"
        case .userProvided: return "用户提供"
        }
    }

    private func unitName(_ unit: FoodMeasurementUnit) -> String {
        switch unit {
        case .gram: return "克"
        case .milliliter: return "毫升"
        case .serving: return "份"
        }
    }
}
