import CoreData
import SwiftUI

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomFood.updatedAt, ascending: false)],
        animation: .default
    ) private var customFoods: FetchedResults<CustomFood>

    let database: FoodDatabaseService
    let onSelect: (FoodReference) -> Void

    @State private var query = ""
    @State private var editorDestination: CustomFoodEditorDestination?
    @State private var errorMessage: String?

    private var matchingCustomFoodRows: [CustomFoodSearchRow] {
        var rows: [CustomFoodSearchRow] = []
        let normalized = normalizedQuery

        for customFood in customFoods {
            let loadState = CustomFoodContentLoadState.load(
                aliasesJSON: customFood.aliasesJSON,
                portionsJSON: customFood.portionsJSON
            )
            guard let serializedContent = loadState.content else {
                let searchableValues = [customFood.name, customFood.brandName ?? ""]
                if matchesQuery(searchableValues, normalized: normalized) {
                    rows.append(.unreadable(
                        customFood,
                        loadState.errorMessage ?? "自定义食物数据无法读取"
                    ))
                }
                continue
            }

            let reference = customFood.foodReference(
                serializedContent: serializedContent
            )
            let searchableValues = [reference.name, reference.brandName ?? ""]
                + reference.aliases
                + reference.display.tags
            if matchesQuery(searchableValues, normalized: normalized) {
                rows.append(.available(customFood, reference))
            }
        }
        return rows
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func matchesQuery(_ values: [String], normalized: String) -> Bool {
        normalized.isEmpty
            || values.contains { $0.lowercased().contains(normalized) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !matchingCustomFoodRows.isEmpty {
                    Section("我的食物") {
                        ForEach(matchingCustomFoodRows) { row in
                            switch row {
                            case let .available(customFood, reference):
                                foodButton(reference)
                                    .swipeActions(edge: .trailing) {
                                        deleteButton(customFood)
                                        Button {
                                            openEditor(customFood)
                                        } label: {
                                            Label("编辑", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                            case let .unreadable(customFood, message):
                                unreadableFoodButton(customFood, message: message)
                                    .swipeActions(edge: .trailing) {
                                        deleteButton(customFood)
                                    }
                            }
                        }
                    }
                }

                Section("内置食物") {
                    ForEach(database.search(query)) { food in
                        foodButton(food)
                    }
                }
            }
            .navigationTitle("选择食物")
            .searchable(text: $query, prompt: "搜索名称、别名或品牌")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editorDestination = CustomFoodEditorDestination(customFood: nil)
                    } label: {
                        Label("新建自定义食物", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editorDestination) { destination in
                CustomFoodEditorView(customFood: destination.customFood)
            }
            .alert(
                "操作失败",
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
    }

    private func foodButton(_ food: FoodReference) -> some View {
        Button {
            onSelect(food)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                FoodThumbnailView(food: food)

                metadataTags(for: food)

                Label(sourceLabel(for: food), systemImage: "checkmark.seal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(nutritionBasisText(for: food))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func unreadableFoodButton(
        _ customFood: CustomFood,
        message: String
    ) -> some View {
        Button {
            openEditor(customFood)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Label(customFood.name, systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                Text("无法使用这条自定义食物；可打开后取消或删除。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openEditor(_ customFood: CustomFood) {
        editorDestination = CustomFoodEditorDestination(customFood: customFood)
    }

    private func deleteButton(_ customFood: CustomFood) -> some View {
        Button(role: .destructive) {
            delete(customFood)
        } label: {
            Label("删除", systemImage: "trash")
        }
    }

    private func delete(_ customFood: CustomFood) {
        do {
            try CustomFoodStore().delete(id: customFood.id, context: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func metadataTags(for food: FoodReference) -> some View {
        let tags = [food.brandName, food.source.specification]
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else { return nil }
                return value
            }

        if !tags.isEmpty {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { metadataCapsule($0) }
                }
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(tags, id: \.self) { metadataCapsule($0) }
                }
            }
        }
    }

    private func metadataCapsule(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .lineLimit(2)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.secondary.opacity(0.12), in: Capsule())
    }

    private func sourceLabel(for food: FoodReference) -> String {
        "\(sourceTypeName(food.source.type)) · \(food.source.name)"
    }

    private func nutritionBasisText(for food: FoodReference) -> String {
        let amount = NutritionFormatters.oneDecimal(food.nutritionBasisAmount)
        let basis = "每 \(amount) \(unitName(food.nutritionBasisUnit))"
        return "\(basis)：热量 \(formatted(food.nutrition.calories, unit: "千卡")) · 碳水 \(formatted(food.nutrition.carbohydrates, unit: "克")) · 蛋白质 \(formatted(food.nutrition.protein, unit: "克")) · 脂肪 \(formatted(food.nutrition.fat, unit: "克"))"
    }

    private func formatted(_ value: Double?, unit: String) -> String {
        guard let value else { return "暂无官方数据" }
        return "\(NutritionFormatters.oneDecimal(value)) \(unit)"
    }

    private func sourceTypeName(_ type: FoodSourceType) -> String {
        switch type {
        case .chinaFoodComposition: return "中国食物成分"
        case .brandWebsite: return "品牌官网"
        case .packageLabel: return "官方包装"
        case .officialMenu: return "官方菜单"
        case .userProvided: return "用户提供"
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

private struct CustomFoodEditorDestination: Identifiable {
    let id = UUID()
    let customFood: CustomFood?
}

private enum CustomFoodSearchRow: Identifiable {
    case available(CustomFood, FoodReference)
    case unreadable(CustomFood, String)

    var id: NSManagedObjectID {
        switch self {
        case let .available(customFood, _), let .unreadable(customFood, _):
            return customFood.objectID
        }
    }
}
