import Foundation

struct FoodDisplayMetadata: Codable, Equatable, Sendable {
    let iconKey: String
    let colorKey: String
    let tags: [String]
}
