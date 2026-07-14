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
            CompactFoodNutritionRow(food: food)
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
