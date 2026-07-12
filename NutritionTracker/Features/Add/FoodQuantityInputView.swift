import SwiftUI

struct FoodQuantityInputView: View {
    @Binding var state: AddFoodFormState
    @FocusState private var isQuantityFocused: Bool

    var body: some View {
        Section("食用数量") {
            VStack(alignment: .leading, spacing: 10) {
                Text("数量")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("请输入数量", text: $state.quantity)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($isQuantityFocused)
                    .accessibilityLabel("食用数量")
            }

            Picker("单位", selection: portionBinding) {
                ForEach(state.portions) { portion in
                    Text(portion.name).tag(portion.id)
                }
            }
            .pickerStyle(.menu)

            if let amount = state.convertedBaseAmount, let unit = state.baseUnit {
                LabeledContent("折合用量") {
                    Text("\(NutritionFormatters.oneDecimal(amount)) \(unitName(unit))")
                        .foregroundStyle(.secondary)
                }
            }

            if let validationMessage = state.quantityValidationMessage {
                Label(validationMessage, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        Section("本次实际摄入") {
            nutritionRow(
                title: "热量",
                value: state.actualNutrition?.calories,
                unit: "千卡"
            )
            nutritionRow(
                title: "碳水化合物",
                value: state.actualNutrition?.carbohydrates,
                unit: "克"
            )
            nutritionRow(
                title: "蛋白质",
                value: state.actualNutrition?.protein,
                unit: "克"
            )
            nutritionRow(
                title: "脂肪",
                value: state.actualNutrition?.fat,
                unit: "克"
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    isQuantityFocused = false
                }
            }
        }
    }

    private var portionBinding: Binding<String> {
        Binding(
            get: { state.selectedPortionID },
            set: { state.selectPortion(id: $0) }
        )
    }

    @ViewBuilder
    private func nutritionRow(
        title: String,
        value: Double?,
        unit: String
    ) -> some View {
        LabeledContent(title) {
            if let value {
                Text("\(NutritionFormatters.oneDecimal(value)) \(unit)")
                    .foregroundStyle(.secondary)
            } else {
                Text("暂无官方数据")
                    .foregroundStyle(.orange)
            }
        }
    }

    private func unitName(_ unit: FoodMeasurementUnit) -> String {
        switch unit {
        case .gram: return "克"
        case .milliliter: return "毫升"
        case .serving: return "份"
        }
    }
}
