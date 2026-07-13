import CoreData
import SwiftUI

struct TodayView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest private var records: FetchedResults<FoodRecord>
    @FetchRequest private var goals: FetchedResults<DailyNutritionGoal>
    @FetchRequest private var exercises: FetchedResults<ExerciseRecord>
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \UserProfile.updatedAt, ascending: false)
        ]
    ) private var profiles: FetchedResults<UserProfile>
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \WeightEntry.recordedAt, ascending: false)
        ],
        animation: .default
    ) private var weightEntries: FetchedResults<WeightEntry>
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \WeightGoal.updatedAt, ascending: false)
        ],
        predicate: NSPredicate(format: "isActive == YES"),
        animation: .default
    ) private var weightGoals: FetchedResults<WeightGoal>

    @State private var presentedSheet: TodaySheet?
    @State private var errorMessage: String?
    @State private var mealSuggestions: [MealSuggestion] = []

    private let date: Date
    private let recommendationFoods: [FoodReference]

    init(date: Date = Date(), bundle: Bundle = .main) {
        self.date = date
        recommendationFoods = (try? FoodDatabaseService.loadBundled(bundle: bundle).foods) ?? []
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
        _exercises = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \ExerciseRecord.createdAt, ascending: false)
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

    private var consumedTotal: PartialNutritionTotal {
        DailySummaryCalculator.partialTotal(records.map(\.partialNutritionValues))
    }

    private var consumed: NutritionValues {
        consumedTotal.lowerBound
    }

    private var nutritionPresentation: TodayNutritionPresentation {
        TodayNutritionPresentation(total: consumedTotal)
    }

    private var currentWeight: Double? {
        weightEntries.first?.weightKilograms
    }

    private var energyBalance: DailyEnergyBalance? {
        guard nutritionPresentation.canPresentExactEnergyBalance,
              let profile = profiles.first,
              let currentWeight else { return nil }
        let estimated: Double
        if let sex = profile.biologicalSex {
            estimated = MetabolismCalculator.estimatedBMR(
                weightKilograms: currentWeight,
                heightCentimeters: profile.heightCentimeters,
                age: MetabolismCalculator.age(
                    on: date,
                    birthDate: profile.birthDate
                ),
                sex: sex
            )
        } else if profile.usesManualBMR {
            estimated = profile.manualBMR
        } else {
            return nil
        }
        let bmr = MetabolismCalculator.resolvedBMR(
            manualBMR: profile.usesManualBMR ? profile.manualBMR : nil,
            estimatedBMR: estimated
        )
        return DailyEnergyBalance(
            basalMetabolicRate: bmr,
            activityFactor: profile.resolvedActivityFactor,
            exerciseCalories: exercises.reduce(0) { $0 + $1.activeCalories },
            intakeCalories: consumed.calories
        )
    }

    var body: some View {
        List {
            Section {
                CalorieSummaryCard(
                    intake: nutritionPresentation.calorieIntake
                )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                if consumedTotal.hasMissingOfficialData {
                    Label(
                        "部分记录缺少官方数据",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.orange)
                }
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
                        isComplete: consumedTotal.carbohydratesComplete,
                        color: .orange
                    )
                    MacroProgressRow(
                        title: "蛋白质",
                        consumed: consumed.protein,
                        target: target.protein,
                        remaining: balance.remaining.protein,
                        isComplete: consumedTotal.proteinComplete,
                        color: .blue
                    )
                    MacroProgressRow(
                        title: "脂肪",
                        consumed: consumed.fat,
                        target: target.fat,
                        remaining: balance.remaining.fat,
                        isComplete: consumedTotal.fatComplete,
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
                            presentedSheet = .nutritionGoal
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
                            presentedSheet = .nutritionGoal
                        }
                        .textCase(nil)
                    }
                }
            }

            Section("热量收支（估算）") {
                if let message = nutritionPresentation.energyBalanceUnavailableMessage {
                    SetupPrompt(
                        title: "热量缺口暂不可用",
                        message: message,
                        buttonTitle: nil,
                        action: {}
                    )
                } else if let energyBalance {
                    EnergyBalanceCard(balance: energyBalance)
                } else if profiles.isEmpty {
                    SetupPrompt(
                        title: "请先填写个人资料",
                        message: "填写年龄、身高和日常活动类型后，才能估算基础代谢和热量缺口。",
                        buttonTitle: "填写资料"
                    ) {
                        presentedSheet = .profile
                    }
                } else {
                    SetupPrompt(
                        title: "还没有当前体重",
                        message: "请到“添加”页面记录体重，以计算基础代谢。",
                        buttonTitle: nil,
                        action: {}
                    )
                }
            }

            Section("减脂目标") {
                if let goal = weightGoals.first, let currentWeight {
                    WeightGoalCard(
                        goal: goal,
                        currentWeight: currentWeight,
                        today: date
                    )
                } else if currentWeight != nil {
                    SetupPrompt(
                        title: "还没有减脂目标",
                        message: "设置目标体重、每月减重比例和完成日期。",
                        buttonTitle: "设置目标"
                    ) {
                        presentedSheet = .weightGoal
                    }
                } else {
                    SetupPrompt(
                        title: "记录体重后可设置目标",
                        message: "请先到“添加”页面保存当前体重。",
                        buttonTitle: nil,
                        action: {}
                    )
                }
            }

            Section("后续餐次建议") {
                if goals.isEmpty {
                    Text("设置每日三大营养素目标后，才能生成餐次建议。")
                        .foregroundStyle(.secondary)
                } else if let message = nutritionPresentation
                    .mealSuggestionsUnavailableMessage {
                    Text(message)
                        .foregroundStyle(.secondary)
                } else if recommendationFoods.isEmpty {
                    Text("内置食物数据库暂时无法读取，请使用手动添加。")
                        .foregroundStyle(.secondary)
                } else if mealSuggestions.isEmpty {
                    Label(
                        "今天三大营养素已达标，无需额外加餐",
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)
                } else {
                    ForEach(mealSuggestions) { suggestion in
                        MealSuggestionCard(suggestion: suggestion)
                    }
                }
            }

            Section("今日食物") {
                if records.isEmpty {
                    EmptyFoodRecordsView()
                } else {
                    ForEach(records, id: \.objectID) { record in
                        FoodRecordRow(record: record)
                    }
                    .onDelete(perform: deleteRecords)
                }
            }
        }
        .navigationTitle("今日")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("个人资料") { presentedSheet = .profile }
                    Button("每日营养目标") { presentedSheet = .nutritionGoal }
                    Button("减脂目标") { presentedSheet = .weightGoal }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if !records.isEmpty {
                    EditButton()
                }
            }
        }
        .onAppear {
            createGoalSnapshotIfPossible()
            refreshMealSuggestions()
        }
        .onChange(of: records.count) { _ in
            refreshMealSuggestions()
        }
        .onChange(of: goals.first?.updatedAt) { _ in
            refreshMealSuggestions()
        }
        .sheet(item: $presentedSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .nutritionGoal:
                    DailyGoalEditorView(date: date)
                case .profile:
                    UserProfileEditorView()
                case .weightGoal:
                    WeightGoalEditorView()
                }
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

    private func refreshMealSuggestions() {
        guard nutritionPresentation.canGenerateMealSuggestions,
              let goal = goals.first else {
            mealSuggestions = []
            return
        }
        let target = NutritionValues(
            calories: 0,
            carbohydrates: goal.carbohydrates,
            protein: goal.protein,
            fat: goal.fat
        )
        let remaining = DailyNutritionBalance(
            target: target,
            consumed: consumed
        ).remaining
        mealSuggestions = MealRecommendationService().suggestions(
            remaining: remaining,
            completedMeals: Set(records.map(\.mealType)),
            foods: recommendationFoods
        )
    }
}

private enum TodaySheet: String, Identifiable {
    case nutritionGoal
    case profile
    case weightGoal

    var id: String { rawValue }
}

private struct SetupPrompt: View {
    let title: String
    let message: String
    let buttonTitle: String?
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let buttonTitle {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }
        }
        .padding(.vertical, 5)
    }
}

private struct EnergyBalanceCard: View {
    let balance: DailyEnergyBalance

    var body: some View {
        VStack(spacing: 9) {
            EnergyValueRow(title: "基础代谢", value: balance.basalMetabolicRate)
            EnergyValueRow(title: "日常基础消耗", value: balance.baselineExpenditure)
            EnergyValueRow(title: "今日运动消耗", value: balance.exerciseCalories)
            EnergyValueRow(title: "预计总消耗", value: balance.totalExpenditure)
            EnergyValueRow(title: "食物摄入", value: balance.intakeCalories)
            Divider()
            HStack {
                Text(balance.calorieDeficit >= 0 ? "今日热量缺口" : "今日热量盈余")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(NutritionFormatters.oneDecimal(abs(balance.calorieDeficit))) 千卡")
                    .fontWeight(.bold)
                    .foregroundStyle(balance.calorieDeficit >= 0 ? Color.green : Color.red)
            }
        }
    }
}

private struct EnergyValueRow: View {
    let title: String
    let value: Double

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(NutritionFormatters.oneDecimal(value)) 千卡")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

private struct WeightGoalCard: View {
    @ObservedObject var goal: WeightGoal
    let currentWeight: Double
    let today: Date

    private var progress: Double {
        WeightGoalProjectionCalculator.progress(
            startWeightKilograms: goal.startWeightKilograms,
            currentWeightKilograms: currentWeight,
            targetWeightKilograms: goal.targetWeightKilograms
        )
    }

    private var remainingDays: Int {
        WeightGoalProjectionCalculator.remainingDays(
            from: today,
            to: goal.targetDate
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(NutritionFormatters.oneDecimal(currentWeight)) 公斤")
                    .font(.title3.bold())
                Spacer()
                Text("目标 \(NutritionFormatters.oneDecimal(goal.targetWeightKilograms)) 公斤")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(.green)
            HStack {
                Text("进度 \(NutritionFormatters.oneDecimal(progress * 100))%")
                Spacer()
                Text(goal.targetDate, format: .dateTime.year().month().day())
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if currentWeight <= goal.targetWeightKilograms {
                Text("目标已完成")
                    .font(.headline)
                    .foregroundStyle(.green)
            } else if remainingDays >= 0 {
                Text("距离目标日期还有 \(remainingDays) 天")
                    .font(.headline)
            } else {
                Text("已超过目标日期 \(abs(remainingDays)) 天")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MealSuggestionCard: View {
    let suggestion: MealSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(suggestion.mealType.title, systemImage: mealImage)
                .font(.headline)
                .foregroundStyle(.green)

            ForEach(suggestion.items) { item in
                HStack {
                    Text(item.food.name)
                    Spacer()
                    Text("\(NutritionFormatters.oneDecimal(item.grams)) 克")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            Text(
                "预计：碳水 \(NutritionFormatters.oneDecimal(suggestion.nutrition.carbohydrates)) 克 · "
                + "蛋白质 \(NutritionFormatters.oneDecimal(suggestion.nutrition.protein)) 克 · "
                + "脂肪 \(NutritionFormatters.oneDecimal(suggestion.nutrition.fat)) 克"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }

    private var mealImage: String {
        suggestion.mealType == .snack ? "takeoutbag.and.cup.and.straw" : "fork.knife"
    }
}

private struct CalorieSummaryCard: View {
    let intake: NutritionAmountPresentation

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
                    Text(
                        intake.prefix
                            + NutritionFormatters.oneDecimal(intake.value)
                    )
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
    let isComplete: Bool
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
                Text(
                    "\(isComplete ? "" : "至少 ")"
                        + "\(NutritionFormatters.oneDecimal(consumed)) / "
                        + "\(NutritionFormatters.oneDecimal(target)) 克"
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(color)

            Text(isComplete
                 ? (remaining >= 0
                    ? "还需 \(NutritionFormatters.oneDecimal(remaining)) 克"
                    : "已超出 \(NutritionFormatters.oneDecimal(abs(remaining))) 克")
                 : "已知摄入为下限，目标差额暂不确定")
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
