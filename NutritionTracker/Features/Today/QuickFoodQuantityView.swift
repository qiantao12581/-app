import CoreData
import SwiftUI

struct QuickFoodQuantityView: View {
    @Environment(\.managedObjectContext) private var context

    let mealType: MealType
    let date: Date
    let selection: QuickFoodSelection
    let onSaved: () -> Void

    @State private var state: QuickFoodQuantityState
    @State private var errorMessage: String?

    init(
        mealType: MealType,
        date: Date,
        selection: QuickFoodSelection,
        onSaved: @escaping () -> Void
    ) {
        self.mealType = mealType
        self.date = date
        self.selection = selection
        self.onSaved = onSaved
        _state = State(
            initialValue: QuickFoodQuantityState(
                selection: selection,
                mealType: mealType
            )
        )
    }

    var body: some View {
        Form {
            Section("食物") {
                FoodThumbnailView(food: state.food)
                LabeledContent("餐次", value: mealType.title)
            }

            Section("确认数量") {
                HStack {
                    TextField(
                        "请输入数量",
                        text: Binding(
                            get: { state.quantityText },
                            set: { state.updateQuantity($0) }
                        )
                    )
                    .keyboardType(.decimalPad)
                    Text(selectedPortion?.name ?? "份")
                        .foregroundStyle(.secondary)
                }

                if state.portions.count > 1 {
                    Picker(
                        "计量单位",
                        selection: Binding(
                            get: { state.selectedPortionID },
                            set: { state.selectPortion(id: $0) }
                        )
                    ) {
                        ForEach(state.portions) { portion in
                            Text(portion.name).tag(portion.id)
                        }
                    }
                }

                if let amount = state.baseAmount,
                   let unit = state.baseUnit {
                    LabeledContent(
                        "折合",
                        value: "\(NutritionFormatters.oneDecimal(amount)) \(unit.chineseName)"
                    )
                }
            }

            Section("本次实际摄入") {
                nutritionRow("热量", value: state.nutrition?.calories, unit: "千卡")
                nutritionRow("碳水化合物", value: state.nutrition?.carbohydrates, unit: "克")
                nutritionRow("蛋白质", value: state.nutrition?.protein, unit: "克")
                nutritionRow("脂肪", value: state.nutrition?.fat, unit: "克")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SafeBottomActionBar(title: "确认保存") {
                save()
            }
        }
        .navigationTitle("确认份量")
        .navigationBarTitleDisplayMode(.inline)
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

    private var selectedPortion: FoodPortion? {
        state.portions.first { $0.id == state.selectedPortionID }
    }

    private func nutritionRow(
        _ title: String,
        value: Double?,
        unit: String
    ) -> some View {
        LabeledContent(
            title,
            value: value.map {
                "\(NutritionFormatters.oneDecimal($0)) \(unit)"
            } ?? "暂无官方数据"
        )
    }

    private func save() {
        do {
            try state.validate()
            guard
                let quantity = state.quantityValue,
                let portionName = state.portionName,
                let baseAmount = state.baseAmount,
                let baseUnit = state.baseUnit,
                let nutrition = state.nutrition
            else {
                throw FoodRecordInputError.invalidQuantity
            }

            _ = try FoodRecordStore().save(
                foodName: state.food.name,
                mealType: state.mealType,
                inputMethod: .manual,
                quantity: quantity,
                portionName: portionName,
                baseAmount: baseAmount,
                baseUnit: baseUnit,
                catalogFoodID: state.catalogFoodIDForSave,
                nutrition: nutrition,
                date: date,
                context: context
            )
            onSaved()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
