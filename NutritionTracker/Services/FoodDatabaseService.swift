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
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return foods }

        return foods.filter { food in
            food.name.localizedCaseInsensitiveContains(term)
                || food.aliases.contains {
                    $0.localizedCaseInsensitiveContains(term)
                }
                || food.brandName?.localizedCaseInsensitiveContains(term) == true
                || food.display.tags.contains {
                    $0.localizedCaseInsensitiveContains(term)
                }
        }
    }
}
