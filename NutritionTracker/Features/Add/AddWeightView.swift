import SwiftUI

struct AddWeightView: View {
    @Environment(\.managedObjectContext) private var context

    @State private var weight = ""
    @State private var message: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("今天的体重")
                    Spacer()
                    TextField("例如：75.5", text: $weight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                    Text("公斤")
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("建议在每天相近的时间和条件下测量。")
            }

            Section {
                Button("保存体重") { save() }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }
        }
        .scrollContentBackground(.hidden)
        .alert(
            "体重记录",
            isPresented: Binding(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )
        ) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private func save() {
        do {
            guard let value = Double(weight.replacingOccurrences(of: ",", with: ".")) else {
                throw WeightEntryError.invalidWeight
            }
            try WeightEntryStore().save(
                weightKilograms: value,
                context: context
            )
            weight = ""
            message = "保存成功"
        } catch {
            message = error.localizedDescription
        }
    }
}
