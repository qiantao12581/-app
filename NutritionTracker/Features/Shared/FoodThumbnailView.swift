import SwiftUI

enum FoodThumbnailStyle: Equatable {
    case standard
    case iconOnly
}

struct FoodThumbnailView: View {
    private let name: String
    private let display: FoodDisplayMetadata
    private let accessibilityText: String
    private let style: FoodThumbnailStyle

    init(food: FoodReference, style: FoodThumbnailStyle = .standard) {
        name = food.name
        display = food.display
        self.style = style
        accessibilityText = Self.accessibilityText(
            name: food.name,
            tags: food.display.tags
        )
    }

    init(
        descriptor: RecordFoodThumbnailDescriptor,
        style: FoodThumbnailStyle = .standard
    ) {
        name = descriptor.name
        display = descriptor.display
        self.style = style
        accessibilityText = descriptor.accessibilityLabel
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tileColor.opacity(0.18))
                Image(systemName: symbolName)
                    .font(iconFont)
                    .foregroundStyle(tileColor)
            }
            .frame(width: iconSize, height: iconSize)

            if style == .standard {
                VStack(alignment: .leading, spacing: 5) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !display.tags.isEmpty {
                        HStack(spacing: 5) {
                            ForEach(Array(display.tags.prefix(2)), id: \.self) { tag in
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
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private static func accessibilityText(name: String, tags: [String]) -> String {
        guard !tags.isEmpty else { return name }
        return "\(name)，\(tags.joined(separator: "，"))"
    }

    private var iconSize: CGFloat {
        style == .iconOnly ? 40 : 48
    }

    private var iconFont: Font {
        style == .iconOnly ? .body.weight(.semibold) : .title2.weight(.semibold)
    }

    private var symbolName: String {
        switch display.iconKey {
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
        switch display.colorKey {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        case "gray": return .secondary
        default: return .accentColor
        }
    }
}

extension RecordFoodThumbnailCustomFoodSource {
    init(customFood: CustomFood) {
        do {
            self = .available(try customFood.decodedFoodReference())
        } catch {
            self = .unreadable(
                catalogFoodID: "custom-\(customFood.id.uuidString.lowercased())",
                message: error.localizedDescription
            )
        }
    }
}
