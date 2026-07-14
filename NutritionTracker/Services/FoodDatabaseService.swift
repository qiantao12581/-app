import Foundation

enum FoodDatabaseError: LocalizedError, Equatable {
    case fileNotFound
    case invalidFoodData(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "找不到内置食物数据库"
        case let .invalidFoodData(name):
            return "食物“\(name)”的营养或推荐重量无效"
        }
    }
}

struct FoodDatabaseService: Sendable {
    let foods: [FoodReference]

    init(data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([FoodReference].self, from: data)
        if let invalid = decoded.first(where: { !$0.hasValidNutritionAndPortion }) {
            throw FoodDatabaseError.invalidFoodData(invalid.name)
        }
        foods = decoded
    }

    static func loadBundled(bundle: Bundle = .main) throws -> FoodDatabaseService {
        guard let url = bundle.url(forResource: "foods", withExtension: "json") else {
            throw FoodDatabaseError.fileNotFound
        }
        return try FoodDatabaseService(data: Data(contentsOf: url))
    }

    func search(_ query: String) -> [FoodReference] {
        Self.rankedSearch(query, in: foods)
    }

    static func rankedSearch(
        _ query: String,
        in foods: [FoodReference]
    ) -> [FoodReference] {
        let term = Self.normalizedSearchText(query)
        guard !term.isEmpty else { return foods }

        return foods.compactMap { food -> FoodSearchResult? in
            guard let tier = Self.matchTier(for: food, term: term) else {
                return nil
            }
            return FoodSearchResult(food: food, tier: tier)
        }
        .sorted { lhs, rhs in
            if lhs.tier != rhs.tier {
                return lhs.tier < rhs.tier
            }

            let lhsIsGeneric = lhs.food.brandName == nil
            let rhsIsGeneric = rhs.food.brandName == nil
            if lhsIsGeneric != rhsIsGeneric {
                return lhsIsGeneric
            }

            let nameOrder = lhs.food.name.localizedStandardCompare(rhs.food.name)
            if nameOrder != .orderedSame {
                return nameOrder == .orderedAscending
            }
            return lhs.food.id < rhs.food.id
        }
        .map(\.food)
    }

    private static func matchTier(
        for food: FoodReference,
        term: String
    ) -> FoodSearchMatchTier? {
        let name = normalizedSearchText(food.name)
        let aliases = food.aliases.map(normalizedSearchText)

        if name == term { return .exactName }
        if aliases.contains(term) { return .exactAlias }
        if name.hasPrefix(term) { return .namePrefix }
        if aliases.contains(where: { $0.hasPrefix(term) }) {
            return .aliasPrefix
        }
        if name.contains(term) || aliases.contains(where: { $0.contains(term) }) {
            return .nameOrAliasContains
        }

        let brand = food.brandName.map(normalizedSearchText)
        let tags = food.display.tags.map(normalizedSearchText)
        if brand?.contains(term) == true
            || tags.contains(where: { $0.contains(term) }) {
            return .brandOrTag
        }
        return nil
    }

    private static func normalizedSearchText(_ value: String) -> String {
        let folded = value.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "zh_Hans_CN")
        )
        let ignored = CharacterSet.whitespacesAndNewlines
            .union(.punctuationCharacters)
        return folded.unicodeScalars
            .filter { !ignored.contains($0) }
            .map(String.init)
            .joined()
    }
}

private enum FoodSearchMatchTier: Int, Comparable {
    case exactName = 0
    case exactAlias = 1
    case namePrefix = 2
    case aliasPrefix = 3
    case nameOrAliasContains = 4
    case brandOrTag = 5

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

private struct FoodSearchResult {
    let food: FoodReference
    let tier: FoodSearchMatchTier
}
