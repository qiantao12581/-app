import Foundation

enum RecordFoodThumbnailCustomFoodSource: Equatable, Sendable {
    case available(FoodReference)
    case unreadable(catalogFoodID: String, message: String)

    var catalogFoodID: String {
        switch self {
        case let .available(food):
            return food.id
        case let .unreadable(catalogFoodID, _):
            return catalogFoodID
        }
    }
}

enum RecordFoodThumbnailFallbackReason: Equatable, Sendable {
    case legacyOrManual
    case missingCatalogFood
    case unreadableCustomFood(String)
}

enum RecordFoodThumbnailResolution: Equatable, Sendable {
    case builtIn
    case custom
    case fallback(RecordFoodThumbnailFallbackReason)
}

struct RecordFoodThumbnailDescriptor: Equatable, Sendable {
    let name: String
    let display: FoodDisplayMetadata
    let resolution: RecordFoodThumbnailResolution
    let accessibilityLabel: String
}

struct RecordFoodThumbnailResolver: Sendable {
    private let builtInFoodsByID: [String: FoodReference]
    private let customFoodsByID: [String: RecordFoodThumbnailCustomFoodSource]

    init(
        builtInFoods: [FoodReference],
        customFoods: [RecordFoodThumbnailCustomFoodSource]
    ) {
        builtInFoodsByID = builtInFoods.reduce(into: [:]) { result, food in
            result[food.id] = food
        }
        customFoodsByID = customFoods.reduce(into: [:]) { result, source in
            result[source.catalogFoodID] = source
        }
    }

    func resolve(
        catalogFoodID: String?,
        storedFoodName: String
    ) -> RecordFoodThumbnailDescriptor {
        let name = normalizedName(storedFoodName)
        guard let catalogFoodID = normalizedCatalogID(catalogFoodID) else {
            return fallback(name: name, reason: .legacyOrManual)
        }

        if let food = builtInFoodsByID[catalogFoodID] {
            return descriptor(name: name, food: food, resolution: .builtIn)
        }

        if let customFood = customFoodsByID[catalogFoodID] {
            switch customFood {
            case let .available(food):
                return descriptor(name: name, food: food, resolution: .custom)
            case let .unreadable(_, message):
                return fallback(
                    name: name,
                    reason: .unreadableCustomFood(message)
                )
            }
        }

        return fallback(name: name, reason: .missingCatalogFood)
    }

    private func descriptor(
        name: String,
        food: FoodReference,
        resolution: RecordFoodThumbnailResolution
    ) -> RecordFoodThumbnailDescriptor {
        RecordFoodThumbnailDescriptor(
            name: name,
            display: food.display,
            resolution: resolution,
            accessibilityLabel: accessibilityLabel(
                name: name,
                tags: food.display.tags
            )
        )
    }

    private func fallback(
        name: String,
        reason: RecordFoodThumbnailFallbackReason
    ) -> RecordFoodThumbnailDescriptor {
        let suffix: String
        switch reason {
        case .unreadableCustomFood:
            suffix = "自定义食物数据无法读取"
        case .legacyOrManual, .missingCatalogFood:
            suffix = "食物缩略图不可用"
        }
        return RecordFoodThumbnailDescriptor(
            name: name,
            display: .recordFallback,
            resolution: .fallback(reason),
            accessibilityLabel: "\(name)，\(suffix)"
        )
    }

    private func accessibilityLabel(name: String, tags: [String]) -> String {
        guard !tags.isEmpty else { return name }
        return "\(name)，\(tags.joined(separator: "，"))"
    }

    private func normalizedCatalogID(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private func normalizedName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未命名食物" : trimmed
    }
}

extension FoodDisplayMetadata {
    static let recordFallback = FoodDisplayMetadata(
        iconKey: "fork.knife",
        colorKey: "gray",
        tags: []
    )
}
