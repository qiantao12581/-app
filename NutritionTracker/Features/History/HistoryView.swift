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

    private var summaries: [DailyPartialNutritionSummary] {
        HistorySummaryCalculator.partialSummaries(
            entries: records.map {
                DatedPartialNutritionValues(
                    date: $0.createdAt,
                    nutrition: $0.partialNutritionValues
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
    let summary: DailyPartialNutritionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(summary.date, format: .dateTime.year().month().day().weekday())
                    .font(.headline)
                Spacer()
                Text(
                    partialText(
                        value: summary.nutrition.lowerBound.calories,
                        complete: summary.nutrition.caloriesComplete,
                        unit: "千卡"
                    )
                )
                    .font(.subheadline.weight(.semibold))
            }

            HStack(spacing: 16) {
                HistoryMacroLabel(
                    title: "碳水",
                    value: summary.nutrition.lowerBound.carbohydrates,
                    isComplete: summary.nutrition.carbohydratesComplete
                )
                HistoryMacroLabel(
                    title: "蛋白质",
                    value: summary.nutrition.lowerBound.protein,
                    isComplete: summary.nutrition.proteinComplete
                )
                HistoryMacroLabel(
                    title: "脂肪",
                    value: summary.nutrition.lowerBound.fat,
                    isComplete: summary.nutrition.fatComplete
                )
            }

            if summary.nutrition.hasMissingOfficialData {
                Text("部分记录缺少官方数据")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 5)
    }

    private func partialText(value: Double, complete: Bool, unit: String) -> String {
        "\(complete ? "" : "至少 ")\(NutritionFormatters.oneDecimal(value)) \(unit)"
    }
}

private struct HistoryMacroLabel: View {
    let title: String
    let value: Double
    let isComplete: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(isComplete ? "" : "至少 ")\(NutritionFormatters.oneDecimal(value)) 克")
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

    private var total: PartialNutritionTotal {
        DailySummaryCalculator.partialTotal(records.map(\.partialNutritionValues))
    }

    var body: some View {
        List {
            Section("当天汇总") {
                HistoryDayTotalRow(
                    title: "热量",
                    value: total.lowerBound.calories,
                    unit: "千卡",
                    isComplete: total.caloriesComplete
                )
                HistoryDayTotalRow(
                    title: "碳水化合物",
                    value: total.lowerBound.carbohydrates,
                    unit: "克",
                    isComplete: total.carbohydratesComplete
                )
                HistoryDayTotalRow(
                    title: "蛋白质",
                    value: total.lowerBound.protein,
                    unit: "克",
                    isComplete: total.proteinComplete
                )
                HistoryDayTotalRow(
                    title: "脂肪",
                    value: total.lowerBound.fat,
                    unit: "克",
                    isComplete: total.fatComplete
                )
                if total.hasMissingOfficialData {
                    Label(
                        "部分记录缺少官方数据",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                }
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
    let isComplete: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(isComplete ? "" : "至少 ")\(NutritionFormatters.oneDecimal(value)) \(unit)")
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
                Text(nutrientText(record.partialNutritionValues.calories, unit: "千卡"))
                    .font(.subheadline.weight(.semibold))
            }

            Text(
                "\(NutritionFormatters.oneDecimal(record.presentedQuantity)) "
                + "\(record.presentedPortionName) · "
                + "碳水 \(nutrientText(record.partialNutritionValues.carbohydrates)) · "
                + "蛋白 \(nutrientText(record.partialNutritionValues.protein)) · "
                + "脂肪 \(nutrientText(record.partialNutritionValues.fat))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func nutrientText(_ value: Double?, unit: String = "") -> String {
        guard let value else { return "暂无官方数据" }
        return NutritionFormatters.oneDecimal(value) + (unit.isEmpty ? "" : " \(unit)")
    }
}
