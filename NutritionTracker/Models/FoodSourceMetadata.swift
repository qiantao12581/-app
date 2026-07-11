import Foundation

enum FoodSourceType: String, Codable, Sendable {
    case chinaFoodComposition
    case brandWebsite
    case packageLabel
    case officialMenu
    case userProvided
}

enum FoodDataCompleteness: String, Codable, Sendable {
    case complete
    case missingOfficialFields
}

struct FoodSourceMetadata: Codable, Equatable, Sendable {
    let type: FoodSourceType
    let name: String
    let url: URL?
    let verifiedAt: Date
    let specification: String
}
