import SwiftUI

struct FoodThumbnailView: View {
    let food: FoodReference

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tileColor.opacity(0.18))
                Image(systemName: symbolName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(tileColor)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 5) {
                Text(food.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !food.display.tags.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(Array(food.display.tags.prefix(2)), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .lineLimit(1)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(.secondary.opacity(0.12), in: Capsule())
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard !food.display.tags.isEmpty else { return food.name }
        return "\(food.name)，\(food.display.tags.joined(separator: "，"))"
    }

    private var symbolName: String {
        switch food.display.iconKey {
        case "takeoutbag.and.cup.and.straw":
            return "takeoutbag.and.cup.and.straw"
        case "fish":
            return "fish.fill"
        case "drop":
            return "drop.fill"
        case "leaf":
            return "leaf.fill"
        case "circle.hexagongrid.fill":
            return "circle.hexagongrid.fill"
        case "birthday.cake":
            return "gift.fill"
        default:
            return "fork.knife"
        }
    }

    private var tileColor: Color {
        switch food.display.colorKey {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        default: return .accentColor
        }
    }
}
