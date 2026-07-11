import CoreData
import SwiftUI

struct DailyGoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    let date: Date

    @State private var carbohydrates = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var updateDefaults = true
    @State private var hasLoaded = false
    @State private var errorMessage: String?

    init(date: Date = Date()) {
        self.date = date
    }

    var body: some View {
        Form {
            Section {
                GoalInputRow(title: "碳水化合物", text: $carbohydrates)
                GoalInputRow(title: "蛋白质", text: $protein)
                GoalInputRow(title: "脂肪", text: $fat)
            } header: {
                Text("每日目标")
            } footer: {
                Text("请输入每天计划摄入的三大营养素，单位均为克。")
            }

            Section {
                Toggle("同时设为以后每天的默认目标", isOn: $updateDefaults)
            } footer: {
                Text("已保存的过去日期不会因默认目标变化而改变。")
            }

            Section {
                Button("保存目标") {
                    save()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .navigationTitle("设置营养目标")
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
            Text(errorMessage ?? "未知错误")
        }
    }

    private func loadOnce() {
        guard !hasLoaded else { return }
        hasLoaded = true

        do {
            let goal = try DailyGoalStore().goal(for: date, context: context)
            carbohydrates = NutritionFormatters.oneDecimal(goal.carbohydrates)
            protein = NutritionFormatters.oneDecimal(goal.protein)
            fat = NutritionFormatters.oneDecimal(goal.fat)
        } catch DailyGoalError.missingDefaults {
            // 第一次使用时没有默认值，保留空输入框让用户自行设置。
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        do {
            guard
                let carbohydrateValue = parsed(carbohydrates),
                let proteinValue = parsed(protein),
                let fatValue = parsed(fat)
            else {
                throw DailyGoalError.invalidValues
            }

            try DailyGoalStore().save(
                for: date,
                carbohydrates: carbohydrateValue,
                protein: proteinValue,
                fat: fatValue,
                updateDefaults: updateDefaults,
                context: context
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func parsed(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }
}

private struct GoalInputRow: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("例如：120", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
            Text("克")
                .foregroundStyle(.secondary)
        }
    }
}
