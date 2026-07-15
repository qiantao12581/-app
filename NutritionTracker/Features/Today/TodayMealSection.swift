import SwiftUI

/// “今日”页中的单个餐次区块，直接提供添加和删除入口。
struct TodayMealSection: View {
    let mealType: MealType
    let records: [FoodRecord]
    let thumbnailResolver: RecordFoodThumbnailResolver
    let onAdd: () -> Void
    let onDelete: (FoodRecord) -> Void

    var body: some View {
        Section {
            if records.isEmpty {
                Text("还没有\(mealType.title)记录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(records, id: \.objectID) { record in
                    FoodRecordRow(
                        record: record,
                        thumbnail: thumbnailResolver.resolve(
                            catalogFoodID: record.catalogFoodID,
                            storedFoodName: record.foodName
                        )
                    )
                    .swipeActions(edge: .trailing) {
                        Button("删除", role: .destructive) {
                            onDelete(record)
                        }
                    }
                }
                .onDelete { offsets in
                    for offset in offsets {
                        onDelete(records[offset])
                    }
                }
            }

            Button(action: onAdd) {
                Label("添加食物", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.green)
            .accessibilityLabel("为\(mealType.title)添加食物")
        } header: {
            Text(mealType.title)
        }
    }
}

private struct FoodRecordRow: View {
    @ObservedObject var record: FoodRecord
    let thumbnail: RecordFoodThumbnailDescriptor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                FoodThumbnailView(descriptor: thumbnail)
                Spacer(minLength: 8)
                Text(nutrientText(
                    value: record.partialNutritionValues.calories,
                    unit: "千卡"
                ))
                .font(.subheadline.weight(.semibold))
            }

            HStack {
                Text(
                    "\(NutritionFormatters.oneDecimal(record.presentedQuantity)) "
                        + record.presentedPortionName
                )
                Spacer()
                Text("碳水 \(nutrientText(value: record.partialNutritionValues.carbohydrates))")
                Text("蛋白 \(nutrientText(value: record.partialNutritionValues.protein))")
                Text("脂肪 \(nutrientText(value: record.partialNutritionValues.fat))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func nutrientText(value: Double?, unit: String = "") -> String {
        guard let value else { return "暂无官方数据" }
        let suffix = unit.isEmpty ? "" : " \(unit)"
        return NutritionFormatters.oneDecimal(value) + suffix
    }
}
