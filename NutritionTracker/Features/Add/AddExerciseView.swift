import SwiftUI

struct AddExerciseView: View {
    @Environment(\.managedObjectContext) private var context

    @State private var name = ""
    @State private var activeCalories = ""
    @State private var durationMinutes = ""
    @State private var alert: ExerciseAlert?

    var body: some View {
        Form {
            Section {
                TextField("运动名称，例如：力量训练", text: $name)
                NumberInputRow(
                    title: "主动消耗",
                    placeholder: "例如：300",
                    unit: "千卡",
                    text: $activeCalories
                )
                NumberInputRow(
                    title: "运动时长",
                    placeholder: "可填 0",
                    unit: "分钟",
                    text: $durationMinutes
                )
            } header: {
                Text("运动信息")
            } footer: {
                Text("只填写运动产生的主动消耗，不要包含静息消耗。")
            }
        }
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SafeBottomActionBar(title: "保存到今天") {
                save()
            }
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("知道了"))
            )
        }
    }

    private func save() {
        do {
            guard let calories = decimal(activeCalories) else {
                throw ExerciseInputError.invalidCalories
            }
            let duration = durationMinutes.isEmpty ? 0 : decimal(durationMinutes)
            guard let duration else {
                throw ExerciseInputError.invalidDuration
            }
            try ExerciseRecordStore().save(
                name: name,
                activeCalories: calories,
                durationMinutes: duration,
                context: context
            )
            name = ""
            activeCalories = ""
            durationMinutes = ""
            alert = ExerciseAlert(title: "保存成功", message: "运动记录已加入今天。")
        } catch {
            alert = ExerciseAlert(title: "无法保存", message: error.localizedDescription)
        }
    }

    private func decimal(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }
}

private struct NumberInputRow: View {
    let title: String
    let placeholder: String
    let unit: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ExerciseAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
