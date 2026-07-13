import CoreData
import SwiftUI

struct AddFoodView: View {
    @Environment(\.managedObjectContext) private var context

    @State private var state: AddFoodFormState
    @State private var presentedSheet: PresentedSheet?
    @State private var alertMessage: AlertMessage?

    private let databaseResult: Result<FoodDatabaseService, Error>
    private let inputMethod: InputMethod

    init(
        bundle: Bundle = .main,
        initialFood: FoodReference? = nil,
        inputMethod: InputMethod = .manual
    ) {
        var initialState = AddFoodFormState()
        if let initialFood {
            initialState.select(food: initialFood)
        }
        _state = State(initialValue: initialState)
        self.inputMethod = inputMethod
        databaseResult = Result {
            try FoodDatabaseService.loadBundled(bundle: bundle)
        }
    }

    var body: some View {
        Form {
            Section("食物信息") {
                if inputMethod == .manual {
                    NavigationLink {
                        PhotoFoodView()
                    } label: {
                        Label("拍照或从相册选择", systemImage: "camera.fill")
                    }
                } else {
                    Label("照片添加：请核对所有数据", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    switch databaseResult {
                    case .success:
                        presentedSheet = .foodSearch
                    case let .failure(error):
                        showError(error)
                    }
                } label: {
                    Label("从内置食物库选择", systemImage: "magnifyingglass")
                }

                Button {
                    presentedSheet = .customFood
                } label: {
                    Label("新建自定义食物", systemImage: "plus.circle")
                }

                if let selectedFood = state.selectedFood {
                    FoodThumbnailView(food: selectedFood)
                        .padding(.vertical, 3)
                }

                TextField("食物名称，例如：熟米饭", text: $state.foodName)

                Picker("餐次", selection: $state.mealType) {
                    ForEach(MealType.allCases) { meal in
                        Text(meal.title).tag(meal)
                    }
                }
            }

            if state.isCatalogFood {
                FoodQuantityInputView(state: $state)
            } else {
                manualQuantitySection
                manualNutritionSection

                if let actual = state.actualCompleteNutrition {
                    Section("本次实际摄入") {
                        NutritionPreviewRow(
                            title: "热量",
                            value: actual.calories,
                            unit: "千卡"
                        )
                        NutritionPreviewRow(
                            title: "碳水化合物",
                            value: actual.carbohydrates,
                            unit: "克"
                        )
                        NutritionPreviewRow(
                            title: "蛋白质",
                            value: actual.protein,
                            unit: "克"
                        )
                        NutritionPreviewRow(
                            title: "脂肪",
                            value: actual.fat,
                            unit: "克"
                        )
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SafeBottomActionBar(title: "保存到今天") {
                saveFood()
            }
        }
        .navigationTitle("添加食物")
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .foodSearch:
                if case let .success(database) = databaseResult {
                    FoodSearchView(database: database) { food in
                        state.select(food: food)
                    }
                }
            case .customFood:
                CustomFoodEditorView()
            }
        }
        .alert(item: $alertMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.message),
                dismissButton: .default(Text("知道了"))
            )
        }
    }

    private var manualQuantitySection: some View {
        Section("实际重量") {
            HStack {
                TextField("请输入重量", text: $state.weightGrams)
                    .keyboardType(.decimalPad)
                Text("克")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var manualNutritionSection: some View {
        Section {
            NutrientInputRow(
                title: "热量",
                unit: "千卡",
                text: $state.caloriesPer100Grams
            )
            NutrientInputRow(
                title: "碳水化合物",
                unit: "克",
                text: $state.carbohydratesPer100Grams
            )
            NutrientInputRow(
                title: "蛋白质",
                unit: "克",
                text: $state.proteinPer100Grams
            )
            NutrientInputRow(
                title: "脂肪",
                unit: "克",
                text: $state.fatPer100Grams
            )
        } header: {
            Text("每 100 克营养")
        } footer: {
            Text("手动填写每 100 克的营养数据。")
        }
    }

    private func saveFood() {
        do {
            try state.validate()
            guard
                let quantity = state.quantityValue,
                let portionName = state.selectedPortionName,
                let amount = state.convertedBaseAmount,
                let baseUnit = state.baseUnit,
                let nutrition = state.actualNutrition
            else {
                throw FoodInputError.invalidNutrition
            }
            _ = try FoodRecordStore().save(
                foodName: state.foodName,
                mealType: state.mealType,
                inputMethod: inputMethod,
                quantity: quantity,
                portionName: portionName,
                baseAmount: amount,
                baseUnit: baseUnit,
                catalogFoodID: state.catalogFoodID,
                nutrition: nutrition,
                context: context
            )

            state.reset()
            alertMessage = AlertMessage(
                title: "保存成功",
                message: "食物已经加入今天的记录。"
            )
        } catch {
            showError(error)
        }
    }

    private func showError(_ error: Error) {
        alertMessage = AlertMessage(
            title: "无法保存",
            message: error.localizedDescription
        )
    }
}

private enum PresentedSheet: String, Identifiable {
    case foodSearch
    case customFood
    var id: String { rawValue }
}

private struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct NutrientInputRow: View {
    let title: String
    let unit: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0.0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 110)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}

private struct NutritionPreviewRow: View {
    let title: String
    let value: Double
    let unit: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(NutritionFormatters.oneDecimal(value)) \(unit)")
                .foregroundStyle(.secondary)
        }
    }
}
