import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast:
            return "早餐"
        case .lunch:
            return "午餐"
        case .dinner:
            return "晚餐"
        case .snack:
            return "加餐"
        }
    }
}
