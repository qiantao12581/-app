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

                TextField("食物名称，例如：熟米饭", text: $state.foodName)

                Picker("餐次", selection: $state.mealType) {
                    ForEach(MealType.allCases) { meal in
                        Text(meal.title).tag(meal)
                    }
                }
            }

            Section("实际重量") {
                HStack {
                    TextField("请输入重量", text: $state.weightGrams)
                        .keyboardType(.decimalPad)
                    Text("克")
                        .foregroundStyle(.secondary)
                }
            }

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
                Text("每100克营养")
            } footer: {
                Text("可选择内置食物自动填充，也可以手动修改。")
            }

            if let actual = state.actualNutrition {
                Section("本次实际摄入") {
                    NutritionPreviewRow(title: "热量", value: actual.calories, unit: "千卡")
                    NutritionPreviewRow(
                        title: "碳水化合物",
                        value: actual.carbohydrates,
                        unit: "克"
                    )
                    NutritionPreviewRow(title: "蛋白质", value: actual.protein, unit: "克")
                    NutritionPreviewRow(title: "脂肪", value: actual.fat, unit: "克")
                }
            }

            Section {
                Button {
                    saveFood()
                } label: {
                    Text("保存到今天")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
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

    private func saveFood() {
        do {
            try state.validate()
            guard
                let weight = state.parsedWeight,
                let nutrition = state.actualNutrition
            else {
                throw FoodInputError.invalidNutrition
            }

            let record = FoodRecord(context: context)
            record.id = UUID()
            record.foodName = state.foodName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            record.weightGrams = weight
            record.calories = nutrition.calories
            record.carbohydrates = nutrition.carbohydrates
            record.protein = nutrition.protein
            record.fat = nutrition.fat
            record.createdAt = Date()
            record.mealTypeRawValue = state.mealType.rawValue
            record.inputMethodRawValue = inputMethod.rawValue

            do {
                try context.save()
            } catch {
                context.delete(record)
                throw error
            }

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
