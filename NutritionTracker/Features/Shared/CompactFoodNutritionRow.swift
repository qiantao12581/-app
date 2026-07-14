import SwiftUI

struct CompactFoodNutritionRow: View {
    let food: FoodReference

    private var presentation: FoodNutritionRowPresentation {
        FoodNutritionRowPresentation(food: food)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            FoodThumbnailView(food: food, style: .iconOnly)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(presentation.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let brandName = presentation.brandName {
                        Text(brandName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Text(presentation.evidenceBadge)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.secondary.opacity(0.12), in: Capsule())
                }

                Text(presentation.basisAndCalories)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Text(presentation.macros)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.accessibilityLabel)
    }
}
