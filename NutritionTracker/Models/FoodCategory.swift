import Foundation

enum FoodCategory: String, Codable, CaseIterable, Sendable {
    case staple
    case protein
    case vegetable
    case fruit
    case dairy
    case snack
}
