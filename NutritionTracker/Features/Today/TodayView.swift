import CoreData
import SwiftUI

struct TodayView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest private var records: FetchedResults<FoodRecord>
    @FetchRequest private var goals: FetchedResults<DailyNutritionGoal>

    @State private var presentsGoalEditor = false
    @State private var errorMessage: String?

    private let date: Date

    init(date: Date = Date()) {
        self.date = date
        let bounds = date.dayBounds()
        let predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            bounds.lowerBound as NSDate,
            bounds.upperBound as NSDate
        )
        _records = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \FoodRecord.createdAt, ascending: false)
            ],
            predicate: predicate,
            animation: .default
        )

        let goalPredicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            bounds.lowerBound as NSDate,
            bounds.upperBound as NSDate
        )
        _goals = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \DailyNutritionGoal.updatedAt, ascending: false)
            ],
            predicate: goalPredicate,
            animation: .default
        )
    }

    private var consumed: NutritionValues {
        DailySummaryCalculator.total(records.map(\.nutritionValues))
    }

    var body: some View {
        List {
            Section {
                CalorieSummaryCard(calories: consumed.calories)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                if let goal = goals.first {
                    let target = NutritionValues(
                        calories: 0,
                        carbohydrates: goal.carbohydrates,
                        protein: goal.protein,
                        fat: goal.fat
                    )
                    let balance = DailyNutritionBalance(
                        target: target,
                        consumed: consumed
                    )
                    MacroProgressRow(
                        title: "碳水化合物",
                        consumed: consumed.carbohydrates,
                        target: target.carbohydrates,
                        remaining: balance.remaining.carbohydrates,
                        color: .orange
                    )
                    MacroProgressRow(
                        title: "蛋白质",
                        consumed: consumed.protein,
                        target: target.protein,
                        remaining: balance.remaining.protein,
                        color: .blue
                    )
                    MacroProgressRow(
                        title: "脂肪",
                        consumed: consumed.fat,
                        target: target.fat,
                        remaining: balance.remaining.fat,
                        color: .purple
                    )
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("还没有设置每日营养目标")
                            .font(.headline)
                        Text("设置后可以分别查看碳水、蛋白质和脂肪还需摄入多少。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("现在设置") {
                            presentsGoalEditor = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                HStack {
                    Text("三大营养素")
                    Spacer()
                    if !goals.isEmpty {
                        Button("修改目标") {
                            presentsGoalEditor = true
                        }
                        .textCase(nil)
                    }
                }
            }

            Section("今日食物") {
                if records.isEmpty {
                    EmptyFoodRecordsView()
                } else {
                    ForEach(records) { record in
                        FoodRecordRow(record: record)
                    }
                    .onDelete(perform: deleteRecords)
                }
            }
        }
        .navigationTitle("今日")
        .toolbar {
            if !records.isEmpty {
                EditButton()
            }
        }
        .onAppear(perform: createGoalSnapshotIfPossible)
        .sheet(isPresented: $presentsGoalEditor) {
            NavigationStack {
                DailyGoalEditorView(date: date)
            }
        }
        .alert(
            "操作失败",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    private func createGoalSnapshotIfPossible() {
        guard goals.isEmpty else { return }
        do {
            _ = try DailyGoalStore().goal(for: date, context: context)
        } catch DailyGoalError.missingDefaults {
            // 首次使用尚未设置目标，由页面显示设置入口。
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteRecords(at offsets: IndexSet) {
        let targets = offsets.map { records[$0] }
        do {
            try FoodRecordStore().delete(targets, context: context)
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }
    }
}

private struct CalorieSummaryCard: View {
    let calories: Double

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 34))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("今天已摄入")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(NutritionFormatters.oneDecimal(calories))
                        .font(.system(.largeTitle, design: .rounded).bold())
                    Text("千卡")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
        .padding(.vertical, 4)
    }
}

private struct MacroProgressRow: View {
    let title: String
    let consumed: Double
    let target: Double
    let remaining: Double
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(max(consumed / target, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(NutritionFormatters.oneDecimal(consumed)) / \(NutritionFormatters.oneDecimal(target)) 克")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(color)

            Text(remaining >= 0
                 ? "还需 \(NutritionFormatters.oneDecimal(remaining)) 克"
                 : "已超出 \(NutritionFormatters.oneDecimal(abs(remaining))) 克")
                .font(.caption)
                .foregroundStyle(remaining >= 0 ? Color.secondary : Color.red)
        }
        .padding(.vertical, 3)
    }
}

private struct FoodRecordRow: View {
    @ObservedObject var record: FoodRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            HStack {
                Text("\(NutritionFormatters.oneDecimal(record.weightGrams)) 克")
                Spacer()
                Text("碳水 \(NutritionFormatters.oneDecimal(record.carbohydrates))")
                Text("蛋白 \(NutritionFormatters.oneDecimal(record.protein))")
                Text("脂肪 \(NutritionFormatters.oneDecimal(record.fat))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct EmptyFoodRecordsView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text("今天还没有食物记录")
                .font(.headline)
            Text("前往“添加”页面记录第一餐吧。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }
}
