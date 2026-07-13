import Foundation

struct CustomFoodSerializedContent: Equatable, Sendable {
    let aliases: [String]
    let portions: [FoodPortion]
}

struct CustomFoodContentLoadError: LocalizedError, Equatable, Sendable {
    let message: String

    var errorDescription: String? { message }
}

enum CustomFoodContentLoadState: Equatable, Sendable {
    case loaded(CustomFoodSerializedContent)
    case unreadable(String)

    static func load(
        aliasesJSON: Data,
        portionsJSON: Data,
        decoder: JSONDecoder = JSONDecoder()
    ) -> CustomFoodContentLoadState {
        let aliases: [String]
        do {
            aliases = try decoder.decode([String].self, from: aliasesJSON)
        } catch {
            return .unreadable("自定义食物的别名数据无法读取")
        }

        let portions: [FoodPortion]
        do {
            portions = try decoder.decode([FoodPortion].self, from: portionsJSON)
        } catch {
            return .unreadable("自定义食物的份量数据无法读取")
        }

        return .loaded(CustomFoodSerializedContent(
            aliases: aliases,
            portions: portions
        ))
    }

    var content: CustomFoodSerializedContent? {
        guard case let .loaded(content) = self else { return nil }
        return content
    }

    var errorMessage: String? {
        guard case let .unreadable(message) = self else { return nil }
        return message
    }

    var canSave: Bool {
        content != nil
    }
}
