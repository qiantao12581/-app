import SwiftUI

struct QuickFoodPickerView: View {
    let mealType: MealType
    let date: Date
    let foods: [FoodReference]
    let frequentCandidates: [FrequentFoodCandidate]
    let onSelect: (QuickFoodSelection) -> Void
    let onComplete: () -> Void

    @State private var query = ""

    private var foodsByID: [String: FoodReference] {
        Dictionary(foods.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private var frequentRows: [FrequentQuickFoodRow] {
        frequentCandidates.compactMap { candidate in
            let selection: QuickFoodSelection?
            if let catalogID = candidate.catalogFoodID,
               let currentFood = foodsByID[catalogID] {
                selection = .catalog(food: currentFood, remembered: candidate)
            } else if candidate.catalogFoodID == nil {
                selection = .historicalManual(candidate: candidate)
            } else {
                selection = nil
            }
            return selection.map {
                FrequentQuickFoodRow(
                    id: candidate.id,
                    selection: $0,
                    candidate: candidate
                )
            }
        }
    }

    private var searchResults: [FoodReference] {
        let ranked = FoodDatabaseService.rankedSearch(query, in: foods)
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ranked
        }
        let frequentIDs = Set(frequentRows.compactMap(\.selection.catalogFoodIDForSave))
        return ranked.filter { !frequentIDs.contains($0.id) }
    }

    var body: some View {
        List {
            Section("最近常吃") {
                if frequentRows.isEmpty {
                    Text("开始记录后，这里会出现最近常吃的食物")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(frequentRows) { row in
                        Button {
                            onSelect(row.selection)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                CompactFoodNutritionRow(food: row.selection.food)
                                Text(lastQuantityText(row.candidate.lastRecord))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section(query.isEmpty ? "全部食物" : "搜索结果") {
                if searchResults.isEmpty {
                    Text("没有找到匹配的食物")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(searchResults) { food in
                        Button {
                            let remembered = frequentCandidates.first {
                                $0.catalogFoodID == food.id
                            }
                            onSelect(.catalog(food: food, remembered: remembered))
                        } label: {
                            CompactFoodNutritionRow(food: food)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section {
                NavigationLink {
                    AddFoodView(
                        initialMealType: mealType,
                        saveDate: date,
                        onSaved: onComplete
                    )
                } label: {
                    Label("完整添加、拍照或新建食物", systemImage: "square.and.pencil")
                }
            }
        }
        .searchable(text: $query, prompt: "搜索名称、别名或品牌")
    }

    private func lastQuantityText(_ record: FoodRecordSnapshot) -> String {
        "上次：\(NutritionFormatters.oneDecimal(record.quantity)) \(record.portionName)"
    }
}

private struct FrequentQuickFoodRow: Identifiable {
    let id: String
    let selection: QuickFoodSelection
    let candidate: FrequentFoodCandidate
}
