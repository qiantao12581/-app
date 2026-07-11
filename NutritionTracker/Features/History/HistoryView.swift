import CoreData
import SwiftUI

struct HistoryView: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \FoodRecord.createdAt, ascending: false)
        ],
        animation: .default
    )
    private var records: FetchedResults<FoodRecord>

    private var summaries: [DailyNutritionSummary] {
        HistorySummaryCalculator.summaries(
            entries: records.map {
                DatedNutritionValues(
                    date: $0.createdAt,
                    nutrition: $0.nutritionValues
                )
            }
        )
    }

    var body: some View {
        List {
            if summaries.isEmpty {
                EmptyHistoryView()
                    .listRowBackground(Color.clear)
            } else {
                ForEach(summaries) { summary in
                    NavigationLink {
                        HistoryDayView(date: summary.date)
                    } label: {
                        HistorySummaryRow(summary: summary)
                    }
                }
            }
        }
        .navigationTitle("历史")
    }
}

private struct HistorySummaryRow: View {
    let summary: DailyNutritionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(summary.date, format: .dateTime.year().month().day().weekday())
                    .font(.headline)
                Spacer()
                Text("\(NutritionFormatters.oneDecimal(summary.nutrition.calories)) 千卡")
                    .font(.subheadline.weight(.semibold))
            }

            HStack(spacing: 16) {
                HistoryMacroLabel(
                    title: "碳水",
                    value: summary.nutrition.carbohydrates
                )
                HistoryMacroLabel(
                    title: "蛋白质",
                    value: summary.nutrition.protein
                )
                HistoryMacroLabel(
                    title: "脂肪",
                    value: summary.nutrition.fat
                )
            }
        }
        .padding(.vertical, 5)
    }
}

private struct HistoryMacroLabel: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(NutritionFormatters.oneDecimal(value)) 克")
                .font(.caption.weight(.medium))
        }
    }
}

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text("还没有历史记录")
                .font(.headline)
            Text("保存食物后，这里会按日期汇总每天的营养摄入。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

private struct HistoryDayView: View {
    @FetchRequest private var records: FetchedResults<FoodRecord>
    private let date: Date

    init(date: Date) {
        self.date = date
        let bounds = date.dayBounds()
        _records = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \FoodRecord.createdAt, ascending: true)
            ],
            predicate: NSPredicate(
                format: "createdAt >= %@ AND createdAt < %@",
                bounds.lowerBound as NSDate,
                bounds.upperBound as NSDate
            ),
            animation: .default
        )
    }

    private var total: NutritionValues {
        DailySummaryCalculator.total(records.map(\.nutritionValues))
    }

    var body: some View {
        List {
            Section("当天汇总") {
                HistoryDayTotalRow(title: "热量", value: total.calories, unit: "千卡")
                HistoryDayTotalRow(
                    title: "碳水化合物",
                    value: total.carbohydrates,
                    unit: "克"
                )
                HistoryDayTotalRow(title: "蛋白质", value: total.protein, unit: "克")
                HistoryDayTotalRow(title: "脂肪", value: total.fat, unit: "克")
            }

            Section("当天食物") {
                ForEach(records, id: \.objectID) { record in
                    HistoryFoodRecordRow(record: record)
                }
            }
        }
        .navigationTitle(date.formatted(.dateTime.month().day()))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HistoryDayTotalRow: View {
    let title: String
    let value: Double
    let unit: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(NutritionFormatters.oneDecimal(value)) \(unit)")
                .foregroundStyle(.secondary)
        }
    }
}

private struct HistoryFoodRecordRow: View {
    @ObservedObject var record: FoodRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.foodName)
                    .font(.headline)
                Text(record.mealType.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(NutritionFormatters.oneDecimal(record.calories)) 千卡")
                    .font(.subheadline.weight(.semibold))
            }

            Text(
                "\(NutritionFormatters.oneDecimal(record.weightGrams)) 克 · "
                + "碳水 \(NutritionFormatters.oneDecimal(record.carbohydrates)) · "
                + "蛋白 \(NutritionFormatters.oneDecimal(record.protein)) · "
                + "脂肪 \(NutritionFormatters.oneDecimal(record.fat))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
