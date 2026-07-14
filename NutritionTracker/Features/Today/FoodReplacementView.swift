import SwiftUI

struct FoodReplacementView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let catalog: [FoodReference]
    let initialCategory: FoodCategory?
    let excludedFoodIDs: Set<String>
    let onSelect: (FoodReference) -> Void

    @State private var query = ""
    @State private var showsAllCategories: Bool

    init(
        title: String,
        catalog: [FoodReference],
        initialCategory: FoodCategory?,
        excludedFoodIDs: Set<String> = [],
        onSelect: @escaping (FoodReference) -> Void
    ) {
        self.title = title
        self.catalog = catalog
        self.initialCategory = initialCategory
        self.excludedFoodIDs = excludedFoodIDs
        self.onSelect = onSelect
        _showsAllCategories = State(initialValue: initialCategory == nil)
    }

    var body: some View {
        NavigationStack {
            List {
                if initialCategory != nil {
                    Section {
                        Toggle("全部类别", isOn: $showsAllCategories)
                    } header: {
                        Text("类别筛选")
                    } footer: {
                        Text(
                            showsAllCategories
                                ? "当前显示所有类别，选择后会改变原食物类别。"
                                : "默认只显示同类别食物。"
                        )
                    }
                }

                Section("可选食物") {
                    if matchingFoods.isEmpty {
                        Text("没有找到符合条件的食物")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(matchingFoods) { food in
                            Button {
                                onSelect(food)
                                dismiss()
                            } label: {
                                CompactFoodNutritionRow(food: food)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "搜索名称、别名或品牌")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private var matchingFoods: [FoodReference] {
        let eligible = catalog.filter { food in
            guard food.defaultPortion != nil else { return false }
            guard !excludedFoodIDs.contains(food.id) else { return false }
            guard showsAllCategories || food.category == initialCategory else {
                return false
            }
            return true
        }
        return FoodDatabaseService.rankedSearch(query, in: eligible)
    }
}
