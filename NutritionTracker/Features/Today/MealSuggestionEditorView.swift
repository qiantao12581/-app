import CoreData
import SwiftUI
import UIKit

struct MealSuggestionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    @State private var state: MealSuggestionEditorState
    @State private var presentedSheet: MealEditorSheet?
    @State private var errorMessage: String?
    @State private var acknowledgesIncompleteNutrition = false

    private let catalog: [FoodReference]
    private let date: Date

    init(
        suggestion: MealSuggestion,
        dailyRemaining: PartialNutritionValues,
        catalog: [FoodReference],
        date: Date = Date()
    ) {
        self.catalog = catalog
        self.date = date
        _state = State(
            initialValue: MealSuggestionEditorState(
                suggestion: suggestion,
                dailyRemainingBeforeMeal: dailyRemaining,
                catalog: catalog
            )
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section("这餐吃什么") {
                    if state.items.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("这餐还没有食物")
                                .foregroundStyle(.secondary)
                            Button {
                                presentedSheet = .add
                            } label: {
                                Label("添加食物", systemImage: "plus.circle.fill")
                            }
                        }
                        .padding(.vertical, 6)
                    } else {
                        ForEach(state.items) { item in
                            MealDraftItemRow(
                                item: item,
                                onQuantityChange: { text in
                                    mutate {
                                        try state.updateQuantity(
                                            itemID: item.id,
                                            text: text
                                        )
                                    }
                                },
                                onPortionChange: { portionID in
                                    mutate {
                                        try state.selectPortion(
                                            itemID: item.id,
                                            portionID: portionID
                                        )
                                    }
                                },
                                onReplace: {
                                    presentedSheet = .replace(
                                        itemID: item.id,
                                        category: item.food.category
                                    )
                                },
                                onRemove: {
                                    withAnimation {
                                        state.remove(itemID: item.id)
                                    }
                                }
                            )
                        }
                    }
                }

                MealNutritionImpactCard(
                    mealNutrition: state.mealNutrition,
                    remainingAfterMeal: state.remainingAfterMeal,
                    isCalculationAvailable: state.items.allSatisfy {
                        $0.calculation != nil
                    },
                    hasIncompleteNutrition: state.hasIncompleteNutrition
                )

                if state.hasIncompleteNutrition {
                    Section("缺失数据确认") {
                        Toggle(
                            "我已了解缺失项不会按 0 计算",
                            isOn: $acknowledgesIncompleteNutrition
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("编辑\(state.draft.mealType.title)建议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        presentedSheet = .add
                    } label: {
                        Label("添加食物", systemImage: "plus")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        dismissKeyboard()
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SafeBottomActionBar(
                    title: "一次性保存这餐",
                    isDisabled: !state.canSave
                        || (state.hasIncompleteNutrition
                            && !acknowledgesIncompleteNutrition),
                    action: save
                )
            }
            .sheet(item: $presentedSheet) { destination in
                switch destination {
                case .add:
                    FoodReplacementView(
                        title: "添加食物",
                        catalog: catalog,
                        initialCategory: nil,
                        excludedFoodIDs: Set(state.items.map { $0.food.id })
                    ) { food in
                        mutate {
                            try state.add(foodID: food.id)
                            acknowledgesIncompleteNutrition = false
                        }
                    }
                case let .replace(itemID, category):
                    FoodReplacementView(
                        title: "替换食物",
                        catalog: catalog,
                        initialCategory: category
                    ) { food in
                        mutate {
                            try state.replace(
                                itemID: itemID,
                                withFoodID: food.id,
                                allowCategoryChange: true
                            )
                            acknowledgesIncompleteNutrition = false
                        }
                    }
                }
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

    private func mutate(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        do {
            try MealSuggestionBatchStore().save(
                state.draft,
                date: date,
                context: context
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

private enum MealEditorSheet: Identifiable {
    case add
    case replace(itemID: String, category: FoodCategory)

    var id: String {
        switch self {
        case .add:
            return "add"
        case let .replace(itemID, _):
            return "replace-\(itemID)"
        }
    }
}
