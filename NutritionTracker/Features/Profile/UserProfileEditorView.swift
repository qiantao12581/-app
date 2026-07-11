import SwiftUI

struct UserProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    @State private var sex: BiologicalSex = .male
    @State private var birthDate = Calendar.current.date(
        byAdding: .year,
        value: -30,
        to: Date()
    ) ?? Date()
    @State private var height = ""
    @State private var activityLevel: ActivityLevel = .sedentary
    @State private var usesCustomFactor = false
    @State private var customFactor = ""
    @State private var usesManualBMR = false
    @State private var manualBMR = ""
    @State private var hasLoaded = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("基本资料") {
                Picker("生理性别", selection: $sex) {
                    ForEach(BiologicalSex.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                DatePicker(
                    "出生日期",
                    selection: $birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                HStack {
                    Text("身高")
                    Spacer()
                    TextField("例如：175", text: $height)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                    Text("厘米")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Picker("日常活动类型", selection: $activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        VStack(alignment: .leading) {
                            Text("\(level.title)（×\(NutritionFormatters.oneDecimal(level.factor))）")
                        }
                        .tag(level)
                    }
                }
                Toggle("自定义活动系数", isOn: $usesCustomFactor)
                if usesCustomFactor {
                    HStack {
                        Text("活动系数")
                        Spacer()
                        TextField("1.0–2.0", text: $customFactor)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            } header: {
                Text("日常活动")
            } footer: {
                Text("只选择工作和日常生活强度，专项锻炼请单独记录。")
            }

            Section {
                Toggle("手动填写基础代谢", isOn: $usesManualBMR)
                if usesManualBMR {
                    HStack {
                        Text("基础代谢")
                        Spacer()
                        TextField("例如：1650", text: $manualBMR)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("千卡")
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("未启用时使用 Mifflin–St Jeor 公式估算。")
            }

            Section {
                Button("保存个人资料") { save() }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }
        }
        .navigationTitle("个人资料")
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
            guard let profile = try UserProfileStore().profile(context: context) else {
                return
            }
            sex = profile.biologicalSex ?? .male
            birthDate = profile.birthDate
            height = NutritionFormatters.oneDecimal(profile.heightCentimeters)
            activityLevel = profile.activityLevel
            usesCustomFactor = profile.customActivityFactor > 0
            customFactor = profile.customActivityFactor > 0
                ? NutritionFormatters.oneDecimal(profile.customActivityFactor)
                : ""
            usesManualBMR = profile.usesManualBMR
            manualBMR = profile.usesManualBMR
                ? NutritionFormatters.oneDecimal(profile.manualBMR)
                : ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        do {
            guard let heightValue = decimal(height) else {
                throw UserProfileError.invalidHeight
            }
            let factorValue = usesCustomFactor ? decimal(customFactor) : 0
            guard let factorValue else {
                throw UserProfileError.invalidActivityFactor
            }
            let manualValue = usesManualBMR ? decimal(manualBMR) : 0
            guard let manualValue else {
                throw UserProfileError.invalidManualBMR
            }
            try UserProfileStore().save(
                biologicalSex: sex,
                birthDate: birthDate,
                heightCentimeters: heightValue,
                activityLevel: activityLevel,
                customActivityFactor: factorValue,
                usesManualBMR: usesManualBMR,
                manualBMR: manualValue,
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
