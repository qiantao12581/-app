import SwiftUI

struct AddView: View {
    @State private var selection: AddCategory = .food

    var body: some View {
        VStack(spacing: 0) {
            Picker("添加类型", selection: $selection) {
                ForEach(AddCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            switch selection {
            case .food:
                AddFoodView()
            case .exercise:
                AddExerciseView()
            case .weight:
                AddWeightView()
            }
        }
        .navigationTitle("添加")
    }
}

private enum AddCategory: String, CaseIterable, Identifiable {
    case food
    case exercise
    case weight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .food: return "食物"
        case .exercise: return "运动"
        case .weight: return "体重"
        }
    }
}
