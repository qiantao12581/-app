import SwiftUI

struct WeightGoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    @State private var startWeight = ""
    @State private var targetWeight = ""
    @State private var monthlyLossPercent = 4.0
    @State private var targetDateMode: TargetDateMode = .automatic
    @State private var manualTargetDate = Calendar.current.date(
        byAdding: .month,
        value: 3,
        to: Date()
    ) ?? Date()
    @State private var hasLoaded = false
    @State private var errorMessage: String?

    private var projectedDate: Date? {
        guard
            let start = decimal(startWeight),
            let target = decimal(targetWeight)
        else { return nil }
        return WeightGoalProjectionCalculator.estimatedTargetDate(
            from: Date(),
            currentWeightKilograms: start,
            targetWeightKilograms: target,
            monthlyLossRate: monthlyLossPercent / 100
        )
    }

    var body: some View {
        Form {
            Section("体重目标") {
                WeightGoalInputRow(title: "起始体重", text: $startWeight)
                WeightGoalInputRow(title: "目标体重", text: $targetWeight)
            }

            Section {
                Picker("每月降低", selection: $monthlyLossPercent) {
                    Text("3%").tag(3.0)
                    Text("4%").tag(4.0)
                    Text("5%").tag(5.0)
                }
                .pickerStyle(.segmented)

                Picker("完成日期", selection: $targetDateMode) {
                    ForEach(TargetDateMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                if targetDateMode == .manual {
                    DatePicker(
                        "目标日期",
                        selection: $manualTargetDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                } else if let projectedDate {
                    HStack {
                        Text("预计完成")
                        Spacer()
                        Text(projectedDate, format: .dateTime.year().month().day())
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("减脂速度与日期")
            } footer: {
                Text("自动日期按每月复合下降估算；结果仅供一般记录参考。")
            }

            Section {
                Button("保存减脂目标") { save() }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }
        }
        .navigationTitle("减脂目标")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
        }
        .onAppear(perform: loadOnce)
        .alert(
            "无法保存",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadOnce() {
        guard !hasLoaded else { return }
        hasLoaded = true
        do {
            if let current = try WeightEntryStore().currentWeight(context: context) {
                startWeight = NutritionFormatters.oneDecimal(current)
            }
            if let goal = try WeightGoalStore().activeGoal(context: context) {
                startWeight = NutritionFormatters.oneDecimal(goal.startWeightKilograms)
                targetWeight = NutritionFormatters.oneDecimal(goal.targetWeightKilograms)
                monthlyLossPercent = goal.monthlyLossRate * 100
                targetDateMode = goal.targetDateMode
                manualTargetDate = goal.targetDate
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        do {
            guard
                let start = decimal(startWeight),
                let target = decimal(targetWeight)
            else {
                throw WeightGoalError.invalidWeights
            }
            try WeightGoalStore().save(
                startWeightKilograms: start,
                targetWeightKilograms: target,
                startDate: Date(),
                monthlyLossRate: monthlyLossPercent / 100,
                targetDateMode: targetDateMode,
                manualTargetDate: targetDateMode == .manual ? manualTargetDate : nil,
                context: context
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func decimal(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }
}

private struct WeightGoalInputRow: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("公斤", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
            Text("公斤")
                .foregroundStyle(.secondary)
        }
    }
}
