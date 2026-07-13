import CoreData
import SwiftUI

struct CustomFoodEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    private let id: UUID
    private let createdAt: Date?
    private let serializedContentError: String?

    @State private var name: String
    @State private var brandName: String
    @State private var aliases: String
    @State private var basisAmount: String
    @State private var basisUnit: FoodMeasurementUnit
    @State private var calories: String
    @State private var carbohydrates: String
    @State private var protein: String
    @State private var fat: String
    @State private var portions: [EditablePortion]
    @State private var iconKey: String
    @State private var colorKey: String
    @State private var errorMessage: String?

    init(customFood: CustomFood? = nil) {
        id = customFood?.id ?? UUID()
        createdAt = customFood?.createdAt
        let loadState = customFood.map {
            CustomFoodContentLoadState.load(
                aliasesJSON: $0.aliasesJSON,
                portionsJSON: $0.portionsJSON
            )
        }
        serializedContentError = loadState?.errorMessage
        let decodedAliases: [String]
        let decodedPortions: [FoodPortion]
        if let serializedContent = loadState?.content {
            decodedAliases = serializedContent.aliases
            decodedPortions = serializedContent.portions
        } else if customFood == nil {
            decodedAliases = []
            decodedPortions = [
                FoodPortion(
                    id: "gram",
                    name: "克",
                    baseAmount: 1,
                    baseUnit: .gram,
                    allowsDecimalQuantity: true,
                    isDefault: true
                )
            ]
        } else {
            // Existing unreadable rows never expose these placeholders to editable UI.
            decodedAliases = []
            decodedPortions = []
        }

        _name = State(initialValue: customFood?.name ?? "")
        _brandName = State(initialValue: customFood?.brandName ?? "")
        _aliases = State(initialValue: decodedAliases.joined(separator: "，"))
        _basisAmount = State(
            initialValue: customFood.map {
                NutritionFormatters.oneDecimal($0.nutritionBasisAmount)
            } ?? "100.0"
        )
        _basisUnit = State(initialValue: customFood?.nutritionBasisUnit ?? .gram)
        _calories = State(initialValue: Self.text(customFood?.partialNutritionValues.calories))
        _carbohydrates = State(
            initialValue: Self.text(customFood?.partialNutritionValues.carbohydrates)
        )
        _protein = State(initialValue: Self.text(customFood?.partialNutritionValues.protein))
        _fat = State(initialValue: Self.text(customFood?.partialNutritionValues.fat))
        _portions = State(initialValue: decodedPortions.map(EditablePortion.init))
        _iconKey = State(initialValue: customFood?.iconKey ?? FoodCategory.staple.rawValue)
        _colorKey = State(initialValue: customFood?.colorKey ?? FoodCategory.staple.rawValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let serializedContentError {
                    Section {
                        Label(
                            serializedContentError,
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.red)
                        Text("为避免覆盖无法读取的原始数据，编辑和保存已停用。你可以取消，或删除这条自定义食物。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("删除这条自定义食物", role: .destructive) {
                            deleteCustomFood()
                        }
                    } header: {
                        Text("无法载入自定义食物")
                    }
                } else {
                    Section("基本信息") {
                        TextField("名称", text: $name)
                        TextField("品牌（可选）", text: $brandName)
                        TextField("别名，用逗号分隔", text: $aliases)
                    }

                    Section {
                        HStack {
                            TextField("基准数量", text: $basisAmount)
                                .keyboardType(.decimalPad)
                            Picker("单位", selection: $basisUnit) {
                                Text("克").tag(FoodMeasurementUnit.gram)
                                Text("毫升").tag(FoodMeasurementUnit.milliliter)
                                Text("份").tag(FoodMeasurementUnit.serving)
                            }
                        }
                        optionalNutrientRow("热量", unit: "千卡", text: $calories)
                        optionalNutrientRow("碳水化合物", unit: "克", text: $carbohydrates)
                        optionalNutrientRow("蛋白质", unit: "克", text: $protein)
                        optionalNutrientRow("脂肪", unit: "克", text: $fat)
                    } header: {
                        Text("营养基准")
                    } footer: {
                        Text("营养项可以留空，但至少填写一项；留空会在汇总中标记为部分数据。")
                    }

                    Section("份量") {
                        ForEach($portions) { $portion in
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("份量名称", text: $portion.name)
                                HStack {
                                    TextField("换算数量", text: $portion.baseAmount)
                                        .keyboardType(.decimalPad)
                                    Text(unitTitle(basisUnit))
                                        .foregroundStyle(.secondary)
                                }
                                Toggle("默认份量", isOn: defaultBinding(for: portion.id))
                                Toggle("允许小数数量", isOn: $portion.allowsDecimalQuantity)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { portions.remove(atOffsets: $0) }

                        Button {
                            portions.append(
                                EditablePortion(
                                    id: UUID(),
                                    persistedID: UUID().uuidString.lowercased(),
                                    name: "份",
                                    baseAmount: "1.0",
                                    allowsDecimalQuantity: true,
                                    isDefault: portions.isEmpty
                                )
                            )
                        } label: {
                            Label("添加份量", systemImage: "plus.circle")
                        }
                    }

                    Section("外观") {
                        Picker("图标", selection: $iconKey) {
                            ForEach(FoodCategory.allCases, id: \.rawValue) { category in
                                Text(categoryTitle(category)).tag(category.rawValue)
                            }
                        }
                        Picker("颜色", selection: $colorKey) {
                            ForEach(FoodCategory.allCases, id: \.rawValue) { category in
                                Text(categoryTitle(category)).tag(category.rawValue)
                            }
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(createdAt == nil ? "新建自定义食物" : "编辑自定义食物")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(serializedContentError != nil)
                }
            }
        }
    }

    @ViewBuilder
    private func optionalNutrientRow(
        _ title: String,
        unit: String,
        text: Binding<String>
    ) -> some View {
        HStack {
            TextField(title, text: text)
                .keyboardType(.decimalPad)
            Text(unit).foregroundStyle(.secondary)
        }
    }

    private func defaultBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { portions.first(where: { $0.id == id })?.isDefault ?? false },
            set: { newValue in
                guard newValue else {
                    if let index = portions.firstIndex(where: { $0.id == id }) {
                        portions[index].isDefault = false
                    }
                    return
                }
                for index in portions.indices {
                    portions[index].isDefault = portions[index].id == id
                }
            }
        )
    }

    private func save() {
        guard serializedContentError == nil else {
            errorMessage = "原始数据无法读取，不能保存，以免覆盖这条自定义食物"
            return
        }
        do {
            let draft = CustomFoodDraft(
                id: id,
                name: name,
                brandName: brandName,
                aliases: aliases.components(separatedBy: CharacterSet(charactersIn: "，,")),
                nutrition: PartialNutritionValues(
                    calories: try optionalNumber(calories, label: "热量"),
                    carbohydrates: try optionalNumber(carbohydrates, label: "碳水化合物"),
                    protein: try optionalNumber(protein, label: "蛋白质"),
                    fat: try optionalNumber(fat, label: "脂肪")
                ),
                nutritionBasisAmount: try requiredNumber(basisAmount, label: "基准数量"),
                nutritionBasisUnit: basisUnit,
                portions: try portions.map { portion in
                    FoodPortion(
                        id: portion.persistedID,
                        name: portion.name,
                        baseAmount: try requiredNumber(portion.baseAmount, label: "份量"),
                        baseUnit: basisUnit,
                        allowsDecimalQuantity: portion.allowsDecimalQuantity,
                        isDefault: portion.isDefault
                    )
                },
                iconKey: iconKey,
                colorKey: colorKey
            )
            _ = try CustomFoodStore().save(draft, context: context)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteCustomFood() {
        do {
            try CustomFoodStore().delete(id: id, context: context)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func optionalNumber(_ text: String, label: String) throws -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let value = NutritionFormatters.decimal(from: trimmed) else {
            throw CustomFoodEditorError.invalidNumber(label)
        }
        return value
    }

    private func requiredNumber(_ text: String, label: String) throws -> Double {
        guard let value = try optionalNumber(text, label: label) else {
            throw CustomFoodEditorError.invalidNumber(label)
        }
        return value
    }

    private func unitTitle(_ unit: FoodMeasurementUnit) -> String {
        switch unit {
        case .gram: return "克"
        case .milliliter: return "毫升"
        case .serving: return "份"
        }
    }

    private func categoryTitle(_ category: FoodCategory) -> String {
        switch category {
        case .staple: return "主食"
        case .protein: return "蛋白质"
        case .vegetable: return "蔬菜"
        case .fruit: return "水果"
        case .dairy: return "乳制品"
        case .snack: return "零食"
        }
    }

    private static func text(_ value: Double?) -> String {
        value.map(NutritionFormatters.oneDecimal) ?? ""
    }
}

private struct EditablePortion: Identifiable {
    let id: UUID
    var persistedID: String
    var name: String
    var baseAmount: String
    var allowsDecimalQuantity: Bool
    var isDefault: Bool

    init(_ portion: FoodPortion) {
        id = UUID()
        persistedID = portion.id
        name = portion.name
        baseAmount = NutritionFormatters.oneDecimal(portion.baseAmount)
        allowsDecimalQuantity = portion.allowsDecimalQuantity
        isDefault = portion.isDefault
    }

    init(
        id: UUID,
        persistedID: String,
        name: String,
        baseAmount: String,
        allowsDecimalQuantity: Bool,
        isDefault: Bool
    ) {
        self.id = id
        self.persistedID = persistedID
        self.name = name
        self.baseAmount = baseAmount
        self.allowsDecimalQuantity = allowsDecimalQuantity
        self.isDefault = isDefault
    }
}

private enum CustomFoodEditorError: LocalizedError {
    case invalidNumber(String)

    var errorDescription: String? {
        switch self {
        case let .invalidNumber(label): return "\(label)必须是有效数值"
        }
    }
}
