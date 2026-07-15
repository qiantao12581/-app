import SwiftUI

struct QuickAddFoodFlowView: View {
    @Environment(\.dismiss) private var dismiss

    let mealType: MealType
    let date: Date
    let builtInFoods: [FoodReference]
    let customFoods: [FoodReference]
    let recentRecords: [FoodRecordSnapshot]

    @State private var selectedFood: QuickFoodSelection?

    private var allFoods: [FoodReference] {
        var seen = Set<String>()
        return (customFoods + builtInFoods).filter { seen.insert($0.id).inserted }
    }

    private var frequentCandidates: [FrequentFoodCandidate] {
        FrequentFoodService().candidates(
            from: recentRecords,
            mealType: mealType,
            now: date
        )
    }

    var body: some View {
        NavigationStack {
            QuickFoodPickerView(
                mealType: mealType,
                date: date,
                foods: allFoods,
                frequentCandidates: frequentCandidates,
                onSelect: { selectedFood = $0 },
                onComplete: { dismiss() }
            )
            .navigationTitle("添加到\(mealType.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { selectedFood != nil },
                    set: { if !$0 { selectedFood = nil } }
                )
            ) {
                if let selectedFood {
                    QuickFoodQuantityView(
                        mealType: mealType,
                        date: date,
                        selection: selectedFood,
                        onSaved: { dismiss() }
                    )
                }
            }
        }
    }
}
